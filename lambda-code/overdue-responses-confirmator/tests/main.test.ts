import type { Context } from "aws-lambda";
import { EitherAsyncUtils } from "common";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { contextualLoggerMock } from "../../../vitest-setup.ts";
import { confirmOverdueResponses, type OverdueResponse, retrieveNextBatchOfOverdueResponses } from "../src/lib/vault.ts";
import { handler } from "../src/main.ts";

vi.mock("../src/lib/vault.ts");

const retrieveNextBatchOfOverdueResponsesMock = vi.mocked(retrieveNextBatchOfOverdueResponses);
const confirmOverdueResponsesMock = vi.mocked(confirmOverdueResponses);

const NOW_TIMESTAMP_MOCK = new Date("2026-11-23T12:00:00.000Z").getTime();
const FORM_ID = "tz4a98xxat96iws9zmbrgj3a";
const DEFAULT_AGE_IN_DAYS = 45;

const defaultLambdaPayload = {
  formId: FORM_ID,
};

function invokeLambdaHandler(payload: unknown = defaultLambdaPayload): Promise<unknown> {
  return handler(payload, {} as Context);
}

describe("Overdue responses confirmator Lambda", () => {
  beforeEach(() => {
    vi.resetAllMocks();

    vi.useFakeTimers();
    vi.setSystemTime(NOW_TIMESTAMP_MOCK);

    retrieveNextBatchOfOverdueResponsesMock.mockImplementation(() => EitherAsyncUtils.right({ overdueResponses: [] }));
    confirmOverdueResponsesMock.mockImplementation(() => EitherAsyncUtils.rightVoid());
  });

  describe("event validation", () => {
    it.each([{ formId: FORM_ID }, { formId: FORM_ID, ageInDaysAfterResponseConsideredOverdue: 1 }])("accepts a valid payload (testing %s)", async (validPayload) => {
      await expect(invokeLambdaHandler(validPayload)).resolves.not.toThrow();
    });

    it.each([
      { formId: "not-a-cuid" },
      { formId: undefined },
      { ageInDaysAfterResponseConsideredOverdue: -1 },
      { ageInDaysAfterResponseConsideredOverdue: 1.5 },
      { ageInDaysAfterResponseConsideredOverdue: "45" },
    ])("rejects an invalid payload (testing %s)", async (invalidPayloadProperty) => {
      await expect(
        invokeLambdaHandler({
          ...defaultLambdaPayload,
          ...invalidPayloadProperty,
        }),
      ).rejects.toThrow("Failed to validate lambda event");
    });
  });

  describe("event configuration", () => {
    it("uses the default age when no age is provided", async () => {
      await invokeLambdaHandler();

      expect(retrieveNextBatchOfOverdueResponsesMock).toHaveBeenCalledExactlyOnceWith(FORM_ID, DEFAULT_AGE_IN_DAYS, undefined);
    });

    it("uses the provided age instead of the default age", async () => {
      const ageInDays = 60;

      await invokeLambdaHandler({
        ...defaultLambdaPayload,
        ageInDaysAfterResponseConsideredOverdue: ageInDays,
      });

      expect(retrieveNextBatchOfOverdueResponsesMock).toHaveBeenCalledExactlyOnceWith(FORM_ID, ageInDays, undefined);
    });

    it("adds the form ID and selected age to the contextual logger metadata", async () => {
      const ageInDays = 60;

      await invokeLambdaHandler({
        ...defaultLambdaPayload,
        ageInDaysAfterResponseConsideredOverdue: ageInDays,
      });

      expect(contextualLoggerMock.addMetadata).toHaveBeenCalledWith("formId", FORM_ID);
      expect(contextualLoggerMock.addMetadata).toHaveBeenCalledWith("ageInDaysAfterResponseConsideredOverdue", `${ageInDays}`);
    });

    it("adds the default age to the contextual logger metadata when no age is provided", async () => {
      await invokeLambdaHandler();

      expect(contextualLoggerMock.addMetadata).toHaveBeenCalledWith("ageInDaysAfterResponseConsideredOverdue", `${DEFAULT_AGE_IN_DAYS}`);
    });
  });

  describe("successful processing", () => {
    it("confirms the retrieved overdue responses", async () => {
      const overdueResponses: OverdueResponse[] = [
        { name: "response-1", createdAt: NOW_TIMESTAMP_MOCK - 60 * 86400000 },
        { name: "response-2", createdAt: NOW_TIMESTAMP_MOCK - 50 * 86400000 },
      ];

      retrieveNextBatchOfOverdueResponsesMock.mockReturnValueOnce(EitherAsyncUtils.right({ overdueResponses }));

      await invokeLambdaHandler();

      expect(confirmOverdueResponsesMock).toHaveBeenCalledExactlyOnceWith(FORM_ID, overdueResponses);
    });

    it("logs the processing progress for a batch of overdue responses", async () => {
      retrieveNextBatchOfOverdueResponsesMock.mockReturnValueOnce(
        EitherAsyncUtils.right({
          overdueResponses: [
            { name: "response-1", createdAt: NOW_TIMESTAMP_MOCK - 60 * 86400000 },
            { name: "response-2", createdAt: NOW_TIMESTAMP_MOCK - 50 * 86400000 },
          ],
        }),
      );

      await invokeLambdaHandler();

      expect(contextualLoggerMock.log).toHaveBeenCalledWith({
        level: "info",
        message: "Targeting responses from 2026-09-24T12:00:00.000Z to 2026-10-04T12:00:00.000Z.\n\n2 new targets have been confirmed.\n\nTotal confirmed casualties: 2.",
      });
    });

    it("logs a summary when overdue responses have been confirmed", async () => {
      retrieveNextBatchOfOverdueResponsesMock.mockReturnValueOnce(
        EitherAsyncUtils.right({
          overdueResponses: [
            { name: "response-1", createdAt: NOW_TIMESTAMP_MOCK - 60 * 86400000 },
            { name: "response-2", createdAt: NOW_TIMESTAMP_MOCK - 50 * 86400000 },
          ],
        }),
      );

      await invokeLambdaHandler();

      expect(contextualLoggerMock.log).toHaveBeenLastCalledWith({
        level: "warn",
        message: `
The Confirmator has confirmed 2 overdue responses (at least 45 days old).

Targeted form: tz4a98xxat96iws9zmbrgj3a
Targeted responses: from 2026-09-24T12:00:00.000Z to 2026-10-04T12:00:00.000Z

Hasta la vista, overdue responses!
`,
      });
    });

    it("logs a summary when no overdue responses are found", async () => {
      await invokeLambdaHandler();

      expect(contextualLoggerMock.log).toHaveBeenLastCalledWith({
        level: "warn",
        message: `
The Confirmator has not found any overdue responses (at least 45 days old).

Targeted form: tz4a98xxat96iws9zmbrgj3a

My work here is done. I'll be back!
`,
      });
    });
  });

  describe("pagination", () => {
    it("retrieves and confirms subsequent batches using the last evaluated key", async () => {
      const lastEvaluatedKey = {
        FormID: FORM_ID,
        "Status#CreatedAt": "Downloaded#1795000000000",
      };

      const firstBatch: OverdueResponse[] = [
        { name: "response-1", createdAt: NOW_TIMESTAMP_MOCK - 60 * 86400000 },
        { name: "response-2", createdAt: NOW_TIMESTAMP_MOCK - 55 * 86400000 },
      ];
      const secondBatch: OverdueResponse[] = [{ name: "response-3", createdAt: NOW_TIMESTAMP_MOCK - 50 * 86400000 }];

      retrieveNextBatchOfOverdueResponsesMock
        .mockReturnValueOnce(EitherAsyncUtils.right({ overdueResponses: firstBatch, lastEvaluatedKey }))
        .mockReturnValueOnce(EitherAsyncUtils.right({ overdueResponses: secondBatch }));

      const invocation = invokeLambdaHandler();
      await vi.runAllTimersAsync(); // Run pending timers to allow the 100 ms delay between batch processing to complete.
      await invocation;

      expect(retrieveNextBatchOfOverdueResponsesMock).toHaveBeenCalledTimes(2);
      expect(retrieveNextBatchOfOverdueResponsesMock).toHaveBeenNthCalledWith(1, FORM_ID, DEFAULT_AGE_IN_DAYS, undefined);
      expect(retrieveNextBatchOfOverdueResponsesMock).toHaveBeenNthCalledWith(2, FORM_ID, DEFAULT_AGE_IN_DAYS, lastEvaluatedKey);
      expect(confirmOverdueResponsesMock).toHaveBeenCalledTimes(2);
      expect(confirmOverdueResponsesMock).toHaveBeenNthCalledWith(1, FORM_ID, firstBatch);
      expect(confirmOverdueResponsesMock).toHaveBeenNthCalledWith(2, FORM_ID, secondBatch);
    });

    it("waits 100 ms before retrieving the next batch", async () => {
      retrieveNextBatchOfOverdueResponsesMock
        .mockReturnValueOnce(
          EitherAsyncUtils.right({
            overdueResponses: [{ name: "response-1", createdAt: NOW_TIMESTAMP_MOCK - 86400000 }],
            lastEvaluatedKey: {
              FormID: FORM_ID,
              "Status#CreatedAt": "Downloaded#1795000000000",
            },
          }),
        )
        .mockReturnValueOnce(EitherAsyncUtils.right({ overdueResponses: [] }));

      const invocation = invokeLambdaHandler();

      await vi.advanceTimersByTimeAsync(99);

      expect(retrieveNextBatchOfOverdueResponsesMock).toHaveBeenCalledTimes(1);

      await vi.advanceTimersByTimeAsync(1);
      await invocation;

      expect(retrieveNextBatchOfOverdueResponsesMock).toHaveBeenCalledTimes(2);
    });

    it("accumulates the total number of confirmed responses across batches", async () => {
      const firstBatch: OverdueResponse[] = Array.from({ length: 25 }, (_, index) => ({ name: `response-${index + 1}`, createdAt: NOW_TIMESTAMP_MOCK - 60 * 86400000 }));
      const secondBatch: OverdueResponse[] = [{ name: "response-26", createdAt: NOW_TIMESTAMP_MOCK - 50 * 86400000 }];

      retrieveNextBatchOfOverdueResponsesMock
        .mockReturnValueOnce(
          EitherAsyncUtils.right({
            overdueResponses: firstBatch,
            lastEvaluatedKey: {
              FormID: FORM_ID,
              "Status#CreatedAt": "Downloaded#1795000000000",
            },
          }),
        )
        .mockReturnValueOnce(EitherAsyncUtils.right({ overdueResponses: secondBatch }));

      const invocation = invokeLambdaHandler();

      await vi.runAllTimersAsync(); // Run pending timers to allow the 100 ms delay between batch processing to complete.
      await invocation;

      expect(contextualLoggerMock.log).toHaveBeenNthCalledWith(1, {
        level: "info",
        message: "Targeting responses from 2026-09-24T12:00:00.000Z to 2026-09-24T12:00:00.000Z.\n\n25 new targets have been confirmed.\n\nTotal confirmed casualties: 25.",
      });

      expect(contextualLoggerMock.log).toHaveBeenNthCalledWith(2, {
        level: "info",
        message: "Targeting responses from 2026-10-04T12:00:00.000Z to 2026-10-04T12:00:00.000Z.\n\n1 new targets have been confirmed.\n\nTotal confirmed casualties: 26.",
      });
    });

    it("preserves the oldest and newest response dates across batches", async () => {
      const oldestDate = NOW_TIMESTAMP_MOCK - 90 * 86400000;
      const middleDate = NOW_TIMESTAMP_MOCK - 70 * 86400000;
      const newestDate = NOW_TIMESTAMP_MOCK - 50 * 86400000;

      const lastEvaluatedKey = {
        FormID: FORM_ID,
        "Status#CreatedAt": "Downloaded#1795000000000",
      };

      retrieveNextBatchOfOverdueResponsesMock.mockReturnValueOnce(EitherAsyncUtils.right({ overdueResponses: [{ name: "response-1", createdAt: oldestDate }], lastEvaluatedKey })).mockReturnValueOnce(
        EitherAsyncUtils.right({
          overdueResponses: [
            { name: "response-2", createdAt: middleDate },
            { name: "response-3", createdAt: newestDate },
          ],
        }),
      );

      const invocation = invokeLambdaHandler();

      await vi.runAllTimersAsync(); // Run pending timers to allow the 100 ms delay between batch processing to complete.
      await invocation;

      expect(contextualLoggerMock.log).toHaveBeenLastCalledWith({
        level: "warn",
        message: `
The Confirmator has confirmed 3 overdue responses (at least 45 days old).

Targeted form: tz4a98xxat96iws9zmbrgj3a
Targeted responses: from ${new Date(oldestDate).toISOString()} to ${new Date(newestDate).toISOString()}

Hasta la vista, overdue responses!
`,
      });
    });
  });

  describe("error handling", () => {
    it("does not try to confirm overdue responses when retrieve operation fails", async () => {
      const error = new Error("Failed to confirm overdue responses");

      retrieveNextBatchOfOverdueResponsesMock.mockReturnValueOnce(EitherAsyncUtils.left(error));

      await expect(invokeLambdaHandler()).rejects.toEqual(error);

      expect(retrieveNextBatchOfOverdueResponsesMock).toHaveBeenCalledTimes(1);
      expect(confirmOverdueResponsesMock).not.toHaveBeenCalled();
    });

    it("does not retrieve subsequent batches when confirmation fails", async () => {
      const error = new Error("Failed to confirm overdue responses");

      retrieveNextBatchOfOverdueResponsesMock.mockReturnValueOnce(
        EitherAsyncUtils.right({
          overdueResponses: [{ name: "response-1", createdAt: NOW_TIMESTAMP_MOCK - 86400000 }],
          lastEvaluatedKey: {
            FormID: FORM_ID,
            "Status#CreatedAt": "Downloaded#1795000000000",
          },
        }),
      );
      confirmOverdueResponsesMock.mockReturnValueOnce(EitherAsyncUtils.left(error));

      await expect(invokeLambdaHandler()).rejects.toEqual(error);

      expect(retrieveNextBatchOfOverdueResponsesMock).toHaveBeenCalledTimes(1);
      expect(confirmOverdueResponsesMock).toHaveBeenCalledTimes(1);
    });

    it("logs an error when retrieving overdue responses fails", async () => {
      const error = new Error("Failed to retrieve overdue responses");

      retrieveNextBatchOfOverdueResponsesMock.mockReturnValueOnce(EitherAsyncUtils.left(error));

      await expect(invokeLambdaHandler()).rejects.toEqual(error);

      expect(contextualLoggerMock.log).toHaveBeenCalledWith({
        level: "error",
        message: "No problemo... just a minor system malfunction.\n\nI'll be back!",
        error,
      });
    });

    it("logs an error when confirming overdue responses fails", async () => {
      const error = new Error("Failed to confirm overdue responses");

      retrieveNextBatchOfOverdueResponsesMock.mockReturnValueOnce(EitherAsyncUtils.right({ overdueResponses: [{ name: "response-1", createdAt: NOW_TIMESTAMP_MOCK - 60 * 86400000 }] }));
      confirmOverdueResponsesMock.mockReturnValueOnce(EitherAsyncUtils.left(error));

      await expect(invokeLambdaHandler()).rejects.toEqual(error);

      expect(contextualLoggerMock.log).toHaveBeenCalledWith({
        level: "error",
        message: "No problemo... just a minor system malfunction.\n\nI'll be back!",
        error,
      });
    });
  });
});
