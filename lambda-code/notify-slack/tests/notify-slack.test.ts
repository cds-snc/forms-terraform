import * as notify_slack from "../src/main.js";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import * as zlib from "zlib";
import { mockClient } from "aws-sdk-client-mock";
import { SSMClient, GetParameterCommand } from "@aws-sdk/client-ssm";
import { sendToSlack } from "../src/slack.js";
import { sendToOpsGenie } from "../src/opsgenie.js";

vi.mock("../src/slack");
const sendToSlackMock = vi.mocked(sendToSlack);

vi.mock("../src/opsgenie");
const sendToOpsGenieMock = vi.mocked(sendToOpsGenie);

const ssmClientMock = mockClient(SSMClient);

describe("handler", () => {
  beforeAll(() => {
    ssmClientMock.on(GetParameterCommand).resolves({ Parameter: { Value: "[]" } });
    process.env.ENVIRONMENT = "production";
  });

  afterEach(() => {
    vi.resetAllMocks();
  });

  it("should return success if no event type is found and it should have called 'send to Slack'", async () => {
    await expect(notify_slack.handler({}, {} as any, () => {})).resolves.not.toThrow();

    expect(sendToSlackMock).toHaveBeenCalled();
  });

  it("should throw an error if the received payload is not compressed", async () => {
    const event = {
      awslogs: {
        data: "not compressed",
      },
    };

    await expect(notify_slack.handler(event, {} as any, () => {})).rejects.toThrow(
      "incorrect header check"
    );
  });

  it("should parse SNS severity for normal message", async () => {
    const message = "dd";
    const result = notify_slack.getSNSMessageSeverity(message);
    expect(result).toBe("info");
  });

  it("should parse SNS severity for SEV1 message", async () => {
    const message = "Hello-sev1";
    const result = notify_slack.getSNSMessageSeverity(message);
    expect(result).toBe("SEV1");
  });

  it("should parse SNS severity for alarm_reset message", async () => {
    const message = 'Hello this is "newstatevalue":"ok"';
    const result = notify_slack.getSNSMessageSeverity(message);
    expect(result).toBe("alarm_reset");
  });

  it("should fail for bad json", async () => {
    const message = `dummy`;
    const result = notify_slack.safeParseLogIncludingJSON(message);
    expect(result).toBe(false);
  });

  it("should extract good json", async () => {
    const message = '{"hello": "world"}';
    const result = notify_slack.safeParseLogIncludingJSON(message);
    expect(result).toStrictEqual({ hello: "world" });
  });

  it("should process aws log", async () => {
    const logData = JSON.stringify({
      messageType: "DATA_MESSAGE",
      owner: "123456789123",
      logGroup: "testLogGroup",
      logStream: "testLogStream",
      subscriptionFilters: ["testFilter"],
      logEvents: [
        {
          id: "eventId1",
          timestamp: 1440442987000,
          message: `{
                    "level": "error",
                    "severity": "1",
                    "msg": "User clcqov5tv000689x5aib9uelt performed GrantFormAccess on Form clfsi1lva008789xagkeouz3w\\nAccess granted to bee@cds-snc.ca"
                }`,
        },
      ],
    });

    const event = {
      awslogs: {
        data: compressAndEncode(logData),
      },
    };

    await expect(notify_slack.handler(event, {} as any, () => {})).resolves.not.toThrow();

    expect(sendToSlackMock).toBeCalledTimes(1);
    expect(sendToOpsGenieMock).toBeCalledTimes(1);
  });

  it("should process AWS logs but fallback for non-JSON messages and should not call OpsGenie", async () => {
    const logData = JSON.stringify({
      messageType: "DATA_MESSAGE",
      owner: "123456789123",
      logGroup: "testLogGroup",
      logStream: "testLogStream",
      subscriptionFilters: ["testFilter"],
      logEvents: [
        {
          id: "eventId1",
          timestamp: 1440442987000,
          message: `DUMMY ERROR`,
        },
      ],
    });

    const event = {
      awslogs: {
        data: compressAndEncode(logData),
      },
    };

    await expect(notify_slack.handler(event, {} as any, () => {})).resolves.not.toThrow();

    expect(sendToSlackMock).toBeCalledTimes(1);
    expect(sendToOpsGenieMock).toBeCalledTimes(0);
  });

  it("should handle SNS events when an SNS record is detected", async () => {
    const event = {
      Records: [
        {
          Sns: {
            Message: "test",
          },
        },
      ],
    };

    await expect(notify_slack.handler(event, {} as any, () => {})).resolves.not.toThrow();

    expect(sendToSlackMock).toBeCalledTimes(1);
    expect(sendToOpsGenieMock).toBeCalledTimes(0);
  });

  it("should handle SNS events when an SNS record is detected and alarm_reset", async () => {
    const event = {
      Records: [
        {
          Sns: {
            Message: 'test "newstatevalue":"ok"',
          },
        },
      ],
    };

    await expect(notify_slack.handler(event, {} as any, () => {})).resolves.not.toThrow();

    expect(sendToSlackMock).toBeCalledTimes(1);
    expect(sendToSlackMock).toHaveBeenCalledWith(
      "CloudWatch Alarm Event",
      'Alarm Status now OK - test "newstatevalue":"ok"',
      "alarm_reset"
    );
    expect(sendToOpsGenieMock).toBeCalledTimes(0);
  });
});

function compressAndEncode(data: string) {
  // Compress the data using zlib
  const compressedData = zlib.gzipSync(data);
  // Encode the compressed data using base64
  const encodedData = compressedData.toString("base64");
  return encodedData;
}
