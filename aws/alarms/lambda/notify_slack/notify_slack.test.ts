/*
 * Since we haven't set allowImportingTsExtensions, you'll need to ensure that only one 'notify_slack' function exists in the path. Therefore, the 'dist' folder must not exist; otherwise, it will find a duplicate.
 */
import { CloudWatchLogsLogEvent, SNSEvent } from "aws-lambda";
import * as notify_slack from "notify_slack";

describe("Unit tests for the lambda handler.", function () {
  it("Verifies default response", async () => {
    const event: CloudWatchLogsLogEvent = {
      queryStringParameters: {}, // this is something we don't use
    } as any;

    jest.spyOn(notify_slack, "sendToOpsGenie");

    const mockSendToSlack = jest.spyOn(notify_slack, "sendToSlack");
    mockSendToSlack.mockImplementation(() => Promise.resolve());

    const result = await notify_slack.handler(event, {} as any, {} as any);
    expect(notify_slack.sendToSlack).toHaveBeenCalled();
    expect(notify_slack.sendToOpsGenie).not.toHaveBeenCalled();

    expect(result.statusCode).toEqual("SUCCESS");
  });

  it("Initiates handling CloudWatch logs when AWS logs are present", async () => {
    const event: CloudWatchLogsLogEvent = {
      awslogs: {},
    } as any;

    const mockHandleCloudWatchLogEvent = jest.spyOn(notify_slack, "handleCloudWatchLogEvent");
    mockHandleCloudWatchLogEvent.mockImplementation(() => Promise.resolve());

    const result = await notify_slack.handler(event, {} as any, {} as any);
    expect(notify_slack.handleCloudWatchLogEvent).toHaveBeenCalled();
    expect(result.statusCode).toEqual("SUCCESS");
  });

  it("Initiates handling SNS events when an SNS record is detected", async () => {
    const event: SNSEvent = {
      Records: [
        {
          Sns: {
            Message: "test",
          },
        },
      ],
    } as any;

    const mockHandleSnsEventFromCloudWatchAlarm = jest.spyOn(
      notify_slack,
      "handleSnsEventFromCloudWatchAlarm"
    );
    mockHandleSnsEventFromCloudWatchAlarm.mockImplementation(() => Promise.resolve());

    const result = await notify_slack.handler(event, {} as any, {} as any);
    expect(notify_slack.handleSnsEventFromCloudWatchAlarm).toHaveBeenCalled();
    expect(result.statusCode).toEqual("SUCCESS");
  });

  it.skip("should throw an error if the received payload is not compressed", async () => {
    const event: CloudWatchLogsLogEvent = {
      awslogs: {
        data: "dummy",
      },
    } as any;

    const result = await notify_slack.handler(event, {} as any, {} as any);
    expect(result.statusCode).toEqual("ERROR");
  });
});
