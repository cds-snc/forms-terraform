import { SendMessageCommand, SQSClient } from "@aws-sdk/client-sqs";
import { EitherAsync } from "purify-ts";

const sqsClient = new SQSClient({
  region: process.env.REGION ?? "ca-central-1",
});

export function enqueueDelayedSubmissionProcessingRequest(submissionId: string, delayInSeconds: number): EitherAsync<Error, { submissionProcessingRequestId: string }> {
  return EitherAsync(() => {
    return sqsClient
      .send(
        new SendMessageCommand({
          MessageBody: JSON.stringify({
            submissionID: submissionId,
          }),
          DelaySeconds: delayInSeconds,
          QueueUrl: process.env.SQS_URL,
        }),
      )
      .then((commandOutput) => {
        if (commandOutput.MessageId === undefined) {
          throw new Error("MessageId is undefined");
        }

        return { submissionProcessingRequestId: commandOutput.MessageId };
      })
      .catch((error) => {
        throw new Error("Failed to enqueue submission processing request", {
          cause: error,
        });
      });
  });
}
