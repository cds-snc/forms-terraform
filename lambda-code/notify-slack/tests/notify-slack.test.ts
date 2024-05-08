import * as notify_slack from "../main.js";
import * as utils from "../utils.js";
import { afterEach, describe, expect, it, vi } from "vitest";
import * as zlib from "zlib";

describe("handler", () => {
  afterEach(() => {
    vi.resetAllMocks();
  });
  it("should return success if no event type is found and it should have called 'send to Slack'", async () => {
    const mockSendToSlack = vi.spyOn(utils, "sendToSlack");
    mockSendToSlack.mockImplementation(() => Promise.resolve());

    const result = await notify_slack.handler({});
    expect(utils.sendToSlack).toHaveBeenCalled();

    expect(result).toStrictEqual({ statusCode: "SUCCESS" });
  });

  it("should throw an error if the received payload is not compressed", async () => {
    const event = {
      awslogs: {
        data: "not compressed",
      },
    };
    const result = await notify_slack.handler(event);
    expect(result.statusCode).toBe("ERROR");
  });

  it("should parse SNS severity for normal message", async () => {
    const message = "dd";
    const result = await notify_slack.getSNSMessageSeverity(message);
    expect(result).toBe("info");
  });

  it("should parse SNS severity for SEV1 message", async () => {
    const message = "Hello-sev1";
    const result = await notify_slack.getSNSMessageSeverity(message);
    expect(result).toBe("SEV1");
  });

  it("should parse SNS severity for alarm_reset message", async () => {
    const message = 'Hello this is "newstatevalue":"ok"';
    const result = await notify_slack.getSNSMessageSeverity(message);
    expect(result).toBe("alarm_reset");
  });

  it("should fail for bad json", async () => {
    const message = `dummy`;
    const result = await notify_slack.safeParseLogIncludingJSON(message);
    expect(result).toBe(false);
  });

  it("should extract good json", async () => {
    const message = '{"hello": "world"}';
    const result = await notify_slack.safeParseLogIncludingJSON(message);
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
                    "severity": 1,
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

    const mockSendToSlack = vi.spyOn(utils, "sendToSlack");
    mockSendToSlack.mockImplementation(() => Promise.resolve());

    const mockSendToOpsGenie = vi.spyOn(utils, "sendToOpsGenie");
    mockSendToOpsGenie.mockImplementation(() => Promise.resolve());

    const result = await notify_slack.handler(event);

    expect(utils.sendToSlack).toBeCalledTimes(1);
    expect(utils.sendToOpsGenie).toBeCalledTimes(1);
    expect(result.statusCode).toBe("SUCCESS");
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

    const mockSendToSlack = vi.spyOn(utils, "sendToSlack");
    mockSendToSlack.mockImplementation(() => Promise.resolve());

    const mockSendToOpsGenie = vi.spyOn(utils, "sendToOpsGenie");
    mockSendToOpsGenie.mockImplementation(() => Promise.resolve());

    const result = await notify_slack.handler(event);

    expect(utils.sendToSlack).toBeCalledTimes(1);
    expect(utils.sendToOpsGenie).toBeCalledTimes(0);
    expect(result.statusCode).toBe("SUCCESS");
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

    const mockSendToSlack = vi.spyOn(utils, "sendToSlack");
    mockSendToSlack.mockImplementation(() => Promise.resolve());

    const mockSendToOpsGenie = vi.spyOn(utils, "sendToOpsGenie");
    mockSendToOpsGenie.mockImplementation(() => Promise.resolve());

    const result = await notify_slack.handler(event);

    expect(utils.sendToSlack).toBeCalledTimes(1);
    expect(utils.sendToOpsGenie).toBeCalledTimes(1);
    expect(result.statusCode).toBe("SUCCESS");
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

    const mockSendToSlack = vi.spyOn(utils, "sendToSlack");
    mockSendToSlack.mockImplementation(() => Promise.resolve());

    const mockSendToOpsGenie = vi.spyOn(utils, "sendToOpsGenie");
    mockSendToOpsGenie.mockImplementation(() => Promise.resolve());

    const result = await notify_slack.handler(event);

    expect(utils.sendToSlack).toBeCalledTimes(1);
    expect(utils.sendToSlack).toHaveBeenCalledWith(
      "CloudWatch Alarm Event",
      'Alarm Status now OK - test "newstatevalue":"ok"',
      "alarm_reset"
    );
    expect(utils.sendToOpsGenie).toBeCalledTimes(1);
    expect(result.statusCode).toBe("SUCCESS");
  });
});

function compressAndEncode(data: string) {
  // Compress the data using zlib
  const compressedData = zlib.gzipSync(data);
  // Encode the compressed data using base64
  const encodedData = compressedData.toString("base64");
  return encodedData;
}
