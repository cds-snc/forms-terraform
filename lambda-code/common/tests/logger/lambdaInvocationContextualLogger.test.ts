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
});
