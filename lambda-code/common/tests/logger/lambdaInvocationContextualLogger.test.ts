import type { Context } from "aws-lambda";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { DefaultLambdaInvocationContextualLogger } from "../../src/logger/lambdaInvocationContextualLogger.ts";

const loggerMock = vi.hoisted(() => ({
  addContext: vi.fn(),
  appendKeys: vi.fn(),
  appendPersistentKeys: vi.fn(),
  info: vi.fn(),
  warn: vi.fn(),
  error: vi.fn(),
}));

vi.mock("@aws-lambda-powertools/logger", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@aws-lambda-powertools/logger")>();

  class MockLogger {
    addContext = loggerMock.addContext;
    appendKeys = loggerMock.appendKeys;
    appendPersistentKeys = loggerMock.appendPersistentKeys;
    info = loggerMock.info;
    warn = loggerMock.warn;
    error = loggerMock.error;
  }

  return {
    ...actual,
    Logger: MockLogger,
  };
});

describe("DefaultContextualLogger", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("adds Lambda context to the logger", () => {
    const logger = DefaultLambdaInvocationContextualLogger.createWithDefaultLogFormatter();
    const context = {
      awsRequestId: "awsRequestId",
    } as Context;

    logger.startInvocationContext(context);

    expect(loggerMock.addContext).toHaveBeenCalledExactlyOnceWith(context);
  });

  it("adds metadata to the logger", () => {
    const logger = DefaultLambdaInvocationContextualLogger.createWithDefaultLogFormatter();

    logger.addMetadata("first", "first");

    expect(loggerMock.appendKeys).toHaveBeenCalledExactlyOnceWith({
      first: "first",
    });
  });

  it("logs an info message", () => {
    const logger = DefaultLambdaInvocationContextualLogger.createWithDefaultLogFormatter();

    logger.log({
      level: "info",
      message: "message",
    });

    expect(loggerMock.info).toHaveBeenCalledExactlyOnceWith("message");
    expect(loggerMock.warn).not.toHaveBeenCalled();
    expect(loggerMock.error).not.toHaveBeenCalled();
  });

  it("logs a warning message", () => {
    const logger = DefaultLambdaInvocationContextualLogger.createWithDefaultLogFormatter();

    logger.log({
      level: "warn",
      message: "message",
    });

    expect(loggerMock.warn).toHaveBeenCalledExactlyOnceWith("message");
    expect(loggerMock.info).not.toHaveBeenCalled();
    expect(loggerMock.error).not.toHaveBeenCalled();
  });

  it("logs an error with the error and severity level", () => {
    const logger = DefaultLambdaInvocationContextualLogger.createWithDefaultLogFormatter();
    const error = new Error("error");

    logger.log({
      level: "error",
      message: "message",
      error,
      severityLevel: "1",
    });

    expect(loggerMock.error).toHaveBeenCalledExactlyOnceWith("message", {
      error,
      severityLevel: "1",
    });
  });

  it("logs an error without a severity level", () => {
    const logger = DefaultLambdaInvocationContextualLogger.createWithDefaultLogFormatter();
    const error = new Error("error");

    logger.log({
      level: "error",
      message: "message",
      error,
    });

    expect(loggerMock.error).toHaveBeenCalledExactlyOnceWith("message", {
      error,
      severityLevel: undefined,
    });
  });
});
