// test utils.ts

import { sendToSlack, sendToOpsGenie } from "./utils.js";
import { afterEach, describe, expect, it, vi } from "vitest";

describe("sendToSlack", () => {
  it("should send a message to Slack", () => {
    const logGroup = "testLogGroup";
    const logMessage = "testLogMessage";
    const logLevel = "testLogLevel";
    const result = sendToSlack(logGroup, logMessage, logLevel);
    expect(result).toBe(true);
  });
});

describe("sendToOpsGenie", () => {
  it("should not send a message to OpsGenie if logLevel is not SEV1", () => {
    const logGroup = "testLogGroup";
    const logMessage = "testLogMessage";
    const logLevel = "testLogLevel";
    const result = sendToOpsGenie(logGroup, logMessage, logLevel);
    expect(result).toBe(false);
  });

  it("should send a message to OpsGenie if logLevel is SEV1", () => {
    const logGroup = "testLogGroup";
    const logMessage = "testLogMessage";
    const logLevel = "SEV1";
    const result = sendToOpsGenie(logGroup, logMessage, logLevel);
    expect(result).toBe(true);
  });

  it("should send a message to OpsGenie if logLevel is 1", () => {
    const logGroup = "testLogGroup";
    const logMessage = "testLogMessage";
    const logLevel = "1";
    const result = sendToOpsGenie(logGroup, logMessage, logLevel);
    expect(result).toBe(true);
  });
});
