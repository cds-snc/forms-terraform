import type { Context } from "aws-lambda";
import { Left, Right } from "purify-ts";
import { EitherAsync } from "purify-ts/EitherAsync";
import { afterEach, describe, expect, it, vi } from "vitest";
import { lambdaWithContextualLogger } from "../src/lambdaWithContextualLogger.ts";
import { DefaultLambdaInvocationContextualLogger } from "../src/logger/lambdaInvocationContextualLogger.ts";

describe("lambdaWithContextualLogger", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("adds the Lambda context to the contextual logger", async () => {
    const startInvocationContextSpy = vi.spyOn(DefaultLambdaInvocationContextualLogger.prototype, "startInvocationContext");

    const context = {
      awsRequestId: "awsRequestId",
    } as Context;

    const wrappedHandler = lambdaWithContextualLogger(() => EitherAsync.liftEither(Right("success")));

    await wrappedHandler({ input: "data" }, context);

    expect(startInvocationContextSpy).toHaveBeenCalledExactlyOnceWith(context);
  });

  it("passes the event, context, and contextual logger to the handler", async () => {
    const event = { input: "data" };
    const context = {
      awsRequestId: "awsRequestId",
    } as Context;

    const handler = vi.fn(() => EitherAsync.liftEither(Right("success")));

    const wrappedHandler = lambdaWithContextualLogger(handler);

    await wrappedHandler(event, context);

    expect(handler).toHaveBeenCalledExactlyOnceWith({
      event,
      context,
      contextualLogger: expect.any(DefaultLambdaInvocationContextualLogger),
    });
  });

  it("returns the output when the handler resolves to Right", async () => {
    const wrappedHandler = lambdaWithContextualLogger(() => EitherAsync.liftEither(Right("success")));

    const result = await wrappedHandler({ input: "data" }, {} as Context);

    expect(result).toEqual("success");
  });

  it("throws the error when the handler resolves to Left", async () => {
    const error = new Error("error");

    const wrappedHandler = lambdaWithContextualLogger(() => EitherAsync.liftEither(Left(error)));

    await expect(wrappedHandler({ input: "data" }, {} as Context)).rejects.toEqual(error);
  });

  it("ends the Lambda invocation context when the handler resolves to Right", async () => {
    const endInvocationContextSpy = vi.spyOn(DefaultLambdaInvocationContextualLogger.prototype, "endInvocationContext");

    const wrappedHandler = lambdaWithContextualLogger(() => EitherAsync.liftEither(Right("success")));

    await wrappedHandler({ input: "data" }, {} as Context);

    expect(endInvocationContextSpy).toHaveBeenCalledOnce();
  });

  it("ends the Lambda invocation context when the handler resolves to Left", async () => {
    const endInvocationContextSpy = vi.spyOn(DefaultLambdaInvocationContextualLogger.prototype, "endInvocationContext");

    const error = new Error("error");

    const wrappedHandler = lambdaWithContextualLogger(() => EitherAsync.liftEither(Left(error)));

    await expect(wrappedHandler({ input: "data" }, {} as Context)).rejects.toThrow();

    expect(endInvocationContextSpy).toHaveBeenCalledOnce();
  });
});
