import type { Context } from "aws-lambda";
import { Left, Right } from "purify-ts";
import { EitherAsync } from "purify-ts/EitherAsync";
import { afterEach, describe, expect, it, vi } from "vitest";
import { z } from "zod";
import { lambdaWithValidatedEventAndContextualLogger } from "../src/lambdaWithValidatedEventAndContextualLogger.ts";
import { DefaultLambdaInvocationContextualLogger } from "../src/logger/lambdaInvocationContextualLogger.ts";

describe("lambdaWithValidatedEventAndContextualLogger", () => {
  const eventSchema = z.object({
    input: z.string(),
  });

  const validEvent = { input: "data" };

  const context = {
    awsRequestId: "awsRequestId",
  } as Context;

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("adds the Lambda context to the contextual logger", async () => {
    const startInvocationContextSpy = vi.spyOn(DefaultLambdaInvocationContextualLogger.prototype, "startInvocationContext");

    const wrappedHandler = lambdaWithValidatedEventAndContextualLogger(eventSchema, () => EitherAsync.liftEither(Right("success")));

    await wrappedHandler(validEvent, context);

    expect(startInvocationContextSpy).toHaveBeenCalledExactlyOnceWith(context);
  });

  it("returns the output when the handler resolves to Right", async () => {
    const wrappedHandler = lambdaWithValidatedEventAndContextualLogger(eventSchema, () => EitherAsync.liftEither(Right("success")));

    const result = await wrappedHandler(validEvent, context);

    expect(result).toEqual("success");
  });

  it("throws the error when the handler resolves to Left", async () => {
    const error = new Error("error");

    const wrappedHandler = lambdaWithValidatedEventAndContextualLogger(eventSchema, () => EitherAsync.liftEither(Left(error)));

    await expect(wrappedHandler(validEvent, context)).rejects.toEqual(error);
  });

  it("validates the event before passing it to the handler", async () => {
    const handler = vi.fn(() => EitherAsync.liftEither(Right("success")));

    const wrappedHandler = lambdaWithValidatedEventAndContextualLogger(eventSchema, handler);

    await wrappedHandler(validEvent, context);

    expect(handler).toHaveBeenCalledExactlyOnceWith({
      event: validEvent,
      context,
      contextualLogger: expect.any(DefaultLambdaInvocationContextualLogger),
    });
  });

  it("throws an error when event validation fails", async () => {
    const handler = vi.fn(() => EitherAsync.liftEither(Right("success")));

    const wrappedHandler = lambdaWithValidatedEventAndContextualLogger(eventSchema, handler);

    await expect(wrappedHandler({ input: 123 }, context)).rejects.toThrow("Failed to validate lambda event");

    expect(handler).not.toHaveBeenCalled();
  });

  it("preserves the Zod validation error as the cause", async () => {
    const handler = vi.fn(() => EitherAsync.liftEither(Right("success")));

    const wrappedHandler = lambdaWithValidatedEventAndContextualLogger(eventSchema, handler);

    await expect(wrappedHandler({ input: 123 }, context)).rejects.toMatchObject({
      message: "Failed to validate lambda event",
      cause: {
        message: "Failed to parse schema",
        cause: [
          expect.objectContaining({
            code: "invalid_type",
            expected: "string",
            path: ["input"],
          }),
        ],
      },
    });

    expect(handler).not.toHaveBeenCalled();
  });

  it("ends the Lambda invocation context when the handler resolves to Right", async () => {
    const endInvocationContextSpy = vi.spyOn(DefaultLambdaInvocationContextualLogger.prototype, "endInvocationContext");

    const wrappedHandler = lambdaWithValidatedEventAndContextualLogger(eventSchema, () => EitherAsync.liftEither(Right("success")));

    await wrappedHandler(validEvent, context);

    expect(endInvocationContextSpy).toHaveBeenCalledOnce();
  });

  it("ends the Lambda invocation context when the handler resolves to Left", async () => {
    const endInvocationContextSpy = vi.spyOn(DefaultLambdaInvocationContextualLogger.prototype, "endInvocationContext");

    const error = new Error("error");

    const wrappedHandler = lambdaWithValidatedEventAndContextualLogger(eventSchema, () => EitherAsync.liftEither(Left(error)));

    await expect(wrappedHandler(validEvent, context)).rejects.toThrow();

    expect(endInvocationContextSpy).toHaveBeenCalledOnce();
  });

  it("ends the Lambda invocation context when event validation fails", async () => {
    const endInvocationContextSpy = vi.spyOn(DefaultLambdaInvocationContextualLogger.prototype, "endInvocationContext");

    const wrappedHandler = lambdaWithValidatedEventAndContextualLogger(eventSchema, () => EitherAsync.liftEither(Right("success")));

    await expect(wrappedHandler({ input: 123 }, context)).rejects.toThrow("Failed to validate lambda event");

    expect(endInvocationContextSpy).toHaveBeenCalledOnce();
  });
});
