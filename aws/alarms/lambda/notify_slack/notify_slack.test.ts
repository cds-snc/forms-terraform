/*
 * Since we haven't set allowImportingTsExtensions, you'll need to ensure that only one 'notify_slack' function exists in the path. Therefore, the 'dist' folder must not exist; otherwise, it will find a duplicate.
 */
import { CloudWatchLogsLogEvent } from "aws-lambda";
import { handler } from "notify_slack";

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
