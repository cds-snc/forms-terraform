import type { Context } from "aws-lambda";
import { Left, Right } from "purify-ts";
import { EitherAsync } from "purify-ts/EitherAsync";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { lambdaWithContextualLogger } from "../src/lambdaWithContextualLogger.ts";

const contextualLoggerMock = vi.hoisted(() => ({
  startInvocationContext: vi.fn(),
  endInvocationContext: vi.fn(),
  addMetadata: vi.fn(),
  log: vi.fn(),
}));

vi.mock("../src/logger/lambdaInvocationContextualLogger.ts", async () => {
  class MockContextualLogger {
    static createWithDefaultLogFormatter() {
      return contextualLoggerMock;
    }

    startInvocationContext = contextualLoggerMock.startInvocationContext;
    endInvocationContext = contextualLoggerMock.endInvocationContext;
    addMetadata = contextualLoggerMock.addMetadata;
    log = contextualLoggerMock.log;
  }

  return {
    DefaultLambdaInvocationContextualLogger: MockContextualLogger,
  };
});

describe("lambdaWithContextualLogger", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("adds the Lambda context to the contextual logger", async () => {
    const context = {
      awsRequestId: "awsRequestId",
    } as Context;

    const wrappedHandler = lambdaWithContextualLogger(() => EitherAsync.liftEither(Right("success")));

    await wrappedHandler({ input: "data" }, context, () => {});

    expect(contextualLoggerMock.startInvocationContext).toHaveBeenCalledExactlyOnceWith(context);
  });

  it("passes the event, context, and contextual logger to the handler", async () => {
    const event = { input: "data" };
    const context = {
      awsRequestId: "awsRequestId",
    } as Context;

    const handler = vi.fn(() => EitherAsync.liftEither(Right("success")));

    const wrappedHandler = lambdaWithContextualLogger(handler);

    await wrappedHandler(event, context, () => {});

    expect(handler).toHaveBeenCalledOnce();
    expect(handler).toHaveBeenCalledWith({
      event,
      context,
      contextualLogger: contextualLoggerMock,
    });
  });

  it("returns the output when the handler resolves to Right", async () => {
    const wrappedHandler = lambdaWithContextualLogger(() => EitherAsync.liftEither(Right("success")));

    const result = await wrappedHandler({ input: "data" }, {} as Context, () => {});

    expect(result).toEqual("success");
  });

  it("throws the error when the handler resolves to Left", async () => {
    const error = new Error("error");

    const wrappedHandler = lambdaWithContextualLogger(() => EitherAsync.liftEither(Left(error)));

    await expect(wrappedHandler({ input: "data" }, {} as Context, () => {})).rejects.toEqual(error);
  });
});
