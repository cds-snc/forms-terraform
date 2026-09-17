import type { UnformattedAttributes } from "@aws-lambda-powertools/logger/types";
import { describe, expect, it } from "vitest";
import { ContextualLogFormatter } from "../../src/logger/contextualLogFormatter.ts";

const timestamp = new Date("2026-09-14T15:00:00.000Z");

const defaultAttributes = {
  timestamp,
  logLevel: "info",
  message: "message",
  serviceName: "serviceName",
  sampleRateValue: 0,
  awsRegion: "awsRegion",
  xRayTraceId: "xRayTraceId",
  lambdaContext: {
    awsRequestId: "awsRequestId",
    coldStart: true,
    functionName: "functionName",
    functionVersion: "functionVersion",
    invokedFunctionArn: "invokedFunctionArn",
    memoryLimitInMB: "memoryLimitInMB",
  },
  environment: "dev",
  error: undefined,
} satisfies UnformattedAttributes;

describe("ContextualLogFormatter", () => {
  it("formats the basic log attributes", () => {
    const formatter = new ContextualLogFormatter();

    const result = formatter.formatAttributes(defaultAttributes, {});

    expect(result.getAttributes()).toEqual({
      timestamp: timestamp.toISOString(),
      level: "info",
      message: "message",
      context: {
        gcForms: {},
        aws: {
          correlationIds: {
            awsRequestId: "awsRequestId",
            xRayTraceId: "xRayTraceId",
          },
          lambdaFunction: {
            coldStart: true,
          },
        },
      },
    });
  });

  it("puts additional attributes into the GC Forms context", () => {
    const formatter = new ContextualLogFormatter();

    const result = formatter.formatAttributes(defaultAttributes, {
      first: "first",
      second: "second",
      third: "third",
    });

    expect(result.getAttributes()).toMatchObject({
      context: {
        gcForms: {
          first: "first",
          second: "second",
          third: "third",
        },
      },
    });
  });

  it("includes the error and severity level attributes when provided", () => {
    const formatter = new ContextualLogFormatter();

    const result = formatter.formatAttributes(defaultAttributes, {
      error: new Error("main error", { cause: new Error("sub error") }),
      severityLevel: "1",
    });

    expect(result.getAttributes()).toMatchObject({
      error: {
        cause: {
          message: "sub error",
          name: "Error",
        },
        message: "main error",
        name: "Error",
      },
      severityLevel: "1",
    });
  });
});
