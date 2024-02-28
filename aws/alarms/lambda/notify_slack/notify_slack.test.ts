import { CloudWatchLogsLogEvent } from "aws-lambda";
import { handler } from "./notify_slack.ts";

describe("Unit test for app handler", function () {
  it("verifies successful response", async () => {
    const event: CloudWatchLogsLogEvent = {
      queryStringParameters: {
        a: "1",
      },
    } as any;
    const result = await handler(event, {} as any, {} as any);

    expect(result.statusCode).toEqual("SUCCESS");
  });
});
