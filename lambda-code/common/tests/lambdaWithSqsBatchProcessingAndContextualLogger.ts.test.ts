import { FullBatchFailureError } from "@aws-lambda-powertools/batch";
import type { Context, SQSEvent, SQSRecord } from "aws-lambda";
import { Left, Right } from "purify-ts";
import { EitherAsync } from "purify-ts/EitherAsync";
import { afterEach, describe, expect, it, vi } from "vitest";
import { lambdaWithSqsBatchProcessingAndContextualLogger } from "../src/lambdaWithSqsBatchProcessingAndContextualLogger.ts";
import { DefaultLambdaInvocationContextualLogger } from "../src/logger/lambdaInvocationContextualLogger.ts";

describe("lambdaWithSqsBatchProcessingAndContextualLogger", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("adds the Lambda context to the contextual logger", async () => {
    const startInvocationContextSpy = vi.spyOn(DefaultLambdaInvocationContextualLogger.prototype, "startInvocationContext");

    const context = {
      awsRequestId: "awsRequestId",
    } as Context;

    const wrappedHandler = lambdaWithSqsBatchProcessingAndContextualLogger(() => EitherAsync.liftEither(Right(undefined)));

    await wrappedHandler(
      {
        Records: [],
      },
      context,
    );

    expect(startInvocationContextSpy).toHaveBeenCalledExactlyOnceWith(context);
  });

  it("passes the SQS record, context, and contextual logger to the handler", async () => {
    const record = {
      messageId: "messageId",
    } as SQSRecord;

    const context = {
      awsRequestId: "awsRequestId",
    } as Context;

    const handler = vi.fn(() => EitherAsync.liftEither(Right(undefined)));

    const wrappedHandler = lambdaWithSqsBatchProcessingAndContextualLogger(handler);

    await wrappedHandler(
      {
        Records: [record],
      },
      context,
    );

    expect(handler).toHaveBeenCalledExactlyOnceWith({
      event: record,
      context,
      contextualLogger: expect.any(DefaultLambdaInvocationContextualLogger),
    });
  });

  it("passes each SQS record to the handler", async () => {
    const record1 = {
      messageId: "messageId1",
    } as SQSRecord;

    const record2 = {
      messageId: "messageId2",
    } as SQSRecord;

    const context = {
      awsRequestId: "awsRequestId",
    } as Context;

    const handler = vi.fn(() => EitherAsync.liftEither(Right(undefined)));

    const wrappedHandler = lambdaWithSqsBatchProcessingAndContextualLogger(handler);

    await wrappedHandler(
      {
        Records: [record1, record2],
      },
      context,
    );

    expect(handler).toHaveBeenCalledTimes(2);

    expect(handler).toHaveBeenCalledWith({
      event: record1,
      context,
      contextualLogger: expect.any(DefaultLambdaInvocationContextualLogger),
    });

    expect(handler).toHaveBeenCalledWith({
      event: record2,
      context,
      contextualLogger: expect.any(DefaultLambdaInvocationContextualLogger),
    });
  });

  it("creates a child contextual logger for each SQS record", async () => {
    const createChildLoggerSpy = vi.spyOn(DefaultLambdaInvocationContextualLogger.prototype, "createChildLogger");

    const event = {
      Records: [
        {
          messageId: "messageId1",
        },
        {
          messageId: "messageId2",
        },
      ],
    } as SQSEvent;

    const wrappedHandler = lambdaWithSqsBatchProcessingAndContextualLogger(() => EitherAsync.liftEither(Right(undefined)));

    await wrappedHandler(event, {} as Context);

    expect(createChildLoggerSpy).toHaveBeenCalledTimes(2);
  });

  it("resolves with success when all handlers resolve to Right", async () => {
    const wrappedHandler = lambdaWithSqsBatchProcessingAndContextualLogger(() => EitherAsync.liftEither(Right(undefined)));

    await expect(
      wrappedHandler(
        {
          Records: [
            {
              messageId: "messageId",
            },
          ],
        } as SQSEvent,
        {} as Context,
      ),
    ).resolves.not.toThrow();
  });

  it("returns a partial batch failure when one record fails to be handled", async () => {
    const wrappedHandler = lambdaWithSqsBatchProcessingAndContextualLogger(({ event }) =>
      event.messageId === "messageId1" ? EitherAsync.liftEither(Right(undefined)) : EitherAsync.liftEither(Left(new Error("error"))),
    );

    await expect(
      wrappedHandler(
        {
          Records: [
            {
              messageId: "messageId1",
            },
            {
              messageId: "messageId2",
            },
          ],
        } as SQSEvent,
        {} as Context,
      ),
    ).resolves.toEqual({
      batchItemFailures: [
        {
          itemIdentifier: "messageId2",
        },
      ],
    });
  });

  it("throws FullBatchFailureError when all records fail to be handled", async () => {
    const wrappedHandler = lambdaWithSqsBatchProcessingAndContextualLogger(() => EitherAsync.liftEither(Left(new Error("error"))));

    await expect(
      wrappedHandler(
        {
          Records: [
            {
              messageId: "messageId1",
            },
            {
              messageId: "messageId2",
            },
          ],
        } as SQSEvent,
        {} as Context,
      ),
    ).rejects.toEqual(expect.any(FullBatchFailureError));
  });

  it("ends the Lambda invocation context when all handlers resolve to Right", async () => {
    const endInvocationContextSpy = vi.spyOn(DefaultLambdaInvocationContextualLogger.prototype, "endInvocationContext");

    const wrappedHandler = lambdaWithSqsBatchProcessingAndContextualLogger(() => EitherAsync.liftEither(Right(undefined)));

    await wrappedHandler(
      {
        Records: [
          {
            messageId: "messageId",
          },
        ],
      } as SQSEvent,
      {} as Context,
    );

    expect(endInvocationContextSpy).toHaveBeenCalledOnce();
  });

  it("ends the Lambda invocation context when a handler resolves to Left", async () => {
    const endInvocationContextSpy = vi.spyOn(DefaultLambdaInvocationContextualLogger.prototype, "endInvocationContext");

    const wrappedHandler = lambdaWithSqsBatchProcessingAndContextualLogger(() => EitherAsync.liftEither(Left(new Error("error"))));

    await expect(
      wrappedHandler(
        {
          Records: [
            {
              messageId: "messageId",
            },
          ],
        } as SQSEvent,
        {} as Context,
      ),
    ).rejects.toThrow();

    expect(endInvocationContextSpy).toHaveBeenCalledOnce();
  });
});
