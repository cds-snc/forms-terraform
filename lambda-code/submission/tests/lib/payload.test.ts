import { describe, expect, it } from "vitest";
import { extractSubmissionPayloadFromLambdaEvent } from "../../src/lib/payload.ts";

const validEvent = {
  formID: "ckz5w4y9s0000abc123456789",
  language: "en",
  responses: { 1: "test", 2: ["one"], 3: "test", 5: "test", 6: "tes@test.com", 7: "English" },
  securityAttribute: "Unclassified",
};

describe("extractSubmissionPayloadFromLambdaEvent", () => {
  it("returns the submission payload when the event is valid", () => {
    const result = extractSubmissionPayloadFromLambdaEvent(validEvent);

    expect(result.extract()).toEqual(validEvent);
  });

  it("returns the submission payload with optional fields", () => {
    const event = {
      ...validEvent,
      fileChecksums: {
        "attachment-1": "0123456789abcdef0123456789abcdef",
        "attachment-2": "abcdef0123456789abcdef0123456789",
      },
      version: 3,
      notificationId: "123e4567-e89b-42d3-a456-426614174000",
    };

    const result = extractSubmissionPayloadFromLambdaEvent(event);

    expect(result.extract()).toEqual(event);
  });

  it.each([
    {
      field: "formID",
      invalidFieldDataFormat: {
        formID: "invalid-form-id",
      },
    },
    {
      field: "language",
      invalidFieldDataFormat: {
        language: "es",
      },
    },
    {
      field: "securityAttribute",
      invalidFieldDataFormat: {
        securityAttribute: "Secret",
      },
    },
    {
      field: "responses",
      invalidFieldDataFormat: {
        responses: "not-an-object",
      },
    },
    {
      field: "fileChecksums",
      invalidFieldDataFormat: {
        fileChecksums: {
          "attachment-1": 123,
        },
      },
    },
    {
      field: "version",
      invalidFieldDataFormat: {
        version: "3",
      },
    },
    {
      field: "notificationId",
      invalidFieldDataFormat: {
        notificationId: "not-a-uuid",
      },
    },
  ])("returns an error when $field is invalid", ({ invalidFieldDataFormat }) => {
    const result = extractSubmissionPayloadFromLambdaEvent({ ...validEvent, ...invalidFieldDataFormat });

    expect(result.extract()).toEqual(new Error("Failed to parse lambda event"));
  });

  it.each(["formID", "language", "responses", "securityAttribute"])("returns an error when %s is missing", (field) => {
    const event = { ...validEvent };

    delete event[field as keyof typeof event];

    const result = extractSubmissionPayloadFromLambdaEvent(event);

    expect(result.extract()).toEqual(new Error("Failed to parse lambda event"));
  });

  it.each(["en", "fr"])("accepts supported languages (testing '%s')", (language) => {
    const result = extractSubmissionPayloadFromLambdaEvent({
      ...validEvent,
      language,
    });

    expect(result.isRight()).toBe(true);
  });

  it.each(["Unclassified", "Protected A", "Protected B"])("accepts supported security attributes (testing '%s')", (securityAttribute) => {
    const result = extractSubmissionPayloadFromLambdaEvent({
      ...validEvent,
      securityAttribute,
    });

    expect(result.isRight()).toBe(true);
  });

  it.each([
    {
      field: "fileChecksums",
      event: {
        ...validEvent,
        fileChecksums: undefined,
      },
    },
    {
      field: "version",
      event: {
        ...validEvent,
        version: undefined,
      },
    },
    {
      field: "notificationId",
      event: {
        ...validEvent,
        notificationId: undefined,
      },
    },
  ])("accepts an undefined value for optional fields (testing $field)", ({ event }) => {
    const result = extractSubmissionPayloadFromLambdaEvent(event);

    expect(result.isRight()).toBe(true);
  });

  it("does not include unknown fields in the parsed payload", () => {
    const result = extractSubmissionPayloadFromLambdaEvent({
      ...validEvent,
      unknownField: "should be removed",
    });

    expect(result.extract()).toEqual(validEvent);
  });
});
