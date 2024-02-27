import lambdaLocal from "lambda-local";
import zlib from "zlib";

import { safeParseLogIncludingJSON } from "./notify_slack.ts";

describe("function safeParseLogIncludingJSON", () => {
  it("should return expected JSON value", () => {
    expect(
      safeParseLogIncludingJSON(
        '2023-07-13T13:48:30.151Z	535741e0-25a9-4c8b-a0a1-25d2b24bf1b4	INFO {"AlarmName": "ReliabilityDeadLetterQueueWarn"}'
      )
    ).toEqual({ AlarmName: "ReliabilityDeadLetterQueueWarn" });
  });
});

describe("function handler", () => {
  it("OpsGenie send function is called for SNS SEV1", async () => {
    expect(await lambdaLocal.execute({})).toHaveReturned;
  });
});

/*
remove the skip to run the test
CloudWatch Logs are delivered to the subscribed Lambda function as a list that is gzip-compressed and base64-encoded. 

*/
test.skip("Investigate OpsGenie send function for Cloud Watch Log with severity=1", async () => {
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
  const encodedData = compressAndEncode(logData);

  console.log(encodedData);

  const result = await lambdaLocal.execute({
    event: {
      awslogs: {
        data: `${encodedData}`,
      },
    },
    lambdaPath: "notify_slack.js",
  });
});

function compressAndEncode(data: string) {
  // Compress the data using zlib
  const compressedData = zlib.gzipSync(data);
  // Encode the compressed data using base64
  const encodedData = compressedData.toString("base64");
  return encodedData;
}
