import { Logger } from "@aws-lambda-powertools/logger";
import type { Context } from "aws-lambda";
import { afterEach, describe, expect, it, vi } from "vitest";
import { LambdaInvocationContextualLogFormatter } from "../../src/logger/lambdaInvocationContextualLogFormatter.ts";
import { DefaultLambdaInvocationContextualLogger } from "../../src/logger/lambdaInvocationContextualLogger.ts";

describe("DefaultContextualLogger", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("adds Lambda context to the logger", () => {
    const addContextSpy = vi.spyOn(Logger.prototype, "addContext");

    const context = {
      awsRequestId: "awsRequestId",
    } as Context;

    const logger = DefaultLambdaInvocationContextualLogger.createWithDefaultLogFormatter();

    logger.startInvocationContext(context);

    expect(addContextSpy).toHaveBeenCalledExactlyOnceWith(context);
  });

  it("ends the Lambda invocation context by resetting the logger keys", () => {
    const resetKeysSpy = vi.spyOn(Logger.prototype, "resetKeys");

    const logger = DefaultLambdaInvocationContextualLogger.createWithDefaultLogFormatter();

    logger.endInvocationContext();

    expect(resetKeysSpy).toHaveBeenCalledOnce();
  });

  it("does not retain metadata after invocation context has been ended", () => {
    const formatAttributesSpy = vi.spyOn(LambdaInvocationContextualLogFormatter.prototype, "formatAttributes");

    const logger = DefaultLambdaInvocationContextualLogger.createWithDefaultLogFormatter();

    logger.addMetadata("firstMetadata", "value1");
    logger.addMetadata("secondMetadata", "value2");

    logger.log({
      level: "info",
      message: "message",
    });

    logger.endInvocationContext();

    logger.addMetadata("thirdMetadata", "value3");

    logger.log({
      level: "info",
      message: "message",
    });

    expect(formatAttributesSpy).toHaveBeenCalledTimes(2);
    expect(formatAttributesSpy).toHaveBeenNthCalledWith(1, expect.any(Object), { firstMetadata: "value1", secondMetadata: "value2" });
    expect(formatAttributesSpy).toHaveBeenNthCalledWith(2, expect.any(Object), { thirdMetadata: "value3" });
  });

  it("adds metadata to the logger", () => {
    const appendKeysSpy = vi.spyOn(Logger.prototype, "appendKeys");

    const logger = DefaultLambdaInvocationContextualLogger.createWithDefaultLogFormatter();

    logger.addMetadata("first", "first");

    expect(appendKeysSpy).toHaveBeenCalledExactlyOnceWith({
      first: "first",
    });
  });

  it("logs an info message", () => {
    const infoLogSpy = vi.spyOn(Logger.prototype, "info");
    const warnLogSpy = vi.spyOn(Logger.prototype, "warn");
    const errorLogSpy = vi.spyOn(Logger.prototype, "error");

    const logger = DefaultLambdaInvocationContextualLogger.createWithDefaultLogFormatter();

    logger.log({
      level: "info",
      message: "message",
    });

    expect(infoLogSpy).toHaveBeenCalledExactlyOnceWith("message");
    expect(warnLogSpy).not.toHaveBeenCalled();
    expect(errorLogSpy).not.toHaveBeenCalled();
  });

  it("logs a warning message", () => {
    const infoLogSpy = vi.spyOn(Logger.prototype, "info");
    const warnLogSpy = vi.spyOn(Logger.prototype, "warn");
    const errorLogSpy = vi.spyOn(Logger.prototype, "error");

    const logger = DefaultLambdaInvocationContextualLogger.createWithDefaultLogFormatter();

    logger.log({
      level: "warn",
      message: "message",
    });

    expect(warnLogSpy).toHaveBeenCalledExactlyOnceWith("message");
    expect(infoLogSpy).not.toHaveBeenCalled();
    expect(errorLogSpy).not.toHaveBeenCalled();
  });

  it("logs an error with the error and severity level", () => {
    const errorLogSpy = vi.spyOn(Logger.prototype, "error");

    const error = new Error("error");

    const logger = DefaultLambdaInvocationContextualLogger.createWithDefaultLogFormatter();

    logger.log({
      level: "error",
      message: "message",
      error,
      severityLevel: "1",
    });

    expect(errorLogSpy).toHaveBeenCalledExactlyOnceWith("message", {
      error,
      severityLevel: "1",
    });
  });

  it("logs an error without a severity level", () => {
    const errorLogSpy = vi.spyOn(Logger.prototype, "error");

    const error = new Error("error");

    const logger = DefaultLambdaInvocationContextualLogger.createWithDefaultLogFormatter();

    logger.log({
      level: "error",
      message: "message",
      error,
    });

    expect(errorLogSpy).toHaveBeenCalledExactlyOnceWith("message", {
      error,
      severityLevel: undefined,
    });
  });

  it("sets isFirstInvocation metadata to true only for the first invocation", () => {
    const appendPersistentKeysSpy = vi.spyOn(Logger.prototype, "appendPersistentKeys");

    const context = {
      awsRequestId: "awsRequestId",
    } as Context;

    const logger = DefaultLambdaInvocationContextualLogger.createWithDefaultLogFormatter();

    logger.startInvocationContext(context);

    expect(appendPersistentKeysSpy).toHaveBeenNthCalledWith(1, { isFirstInvocation: true });

    logger.endInvocationContext();

    logger.startInvocationContext(context);

    expect(appendPersistentKeysSpy).toHaveBeenNthCalledWith(2, { isFirstInvocation: false });
  });

  it("passes the current isFirstInvocation metadata value to child loggers", () => {
    const appendPersistentKeysSpy = vi.spyOn(Logger.prototype, "appendPersistentKeys");

    const context = {
      awsRequestId: "awsRequestId",
    } as Context;

    const logger1 = DefaultLambdaInvocationContextualLogger.createWithDefaultLogFormatter();
    const childLogger1 = logger1.createChildLogger();

    logger1.startInvocationContext(context);
    childLogger1.startInvocationContext(context);

    logger1.log({ level: "info", message: "first" });
    childLogger1.log({ level: "info", message: "first child" });

    // Will ignore call 1 and 4 because the Logger class uses `appendPersistentKeys` when initializing itself as part of the child creation process
    expect(appendPersistentKeysSpy).toHaveBeenNthCalledWith(2, { isFirstInvocation: true });
    expect(appendPersistentKeysSpy).toHaveBeenNthCalledWith(3, { isFirstInvocation: true });

    logger1.endInvocationContext();

    const childLogger2 = logger1.createChildLogger();

    logger1.startInvocationContext(context);
    childLogger2.startInvocationContext(context);

    expect(appendPersistentKeysSpy).toHaveBeenNthCalledWith(5, { isFirstInvocation: false });
    expect(appendPersistentKeysSpy).toHaveBeenNthCalledWith(6, { isFirstInvocation: false });
  });
});
