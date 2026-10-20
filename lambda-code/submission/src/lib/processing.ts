import { SendMessageCommand, type SendMessageCommandOutput } from "@aws-sdk/client-sqs";
import { EitherAsync } from "purify-ts";
import { sqsClient } from "./awsServicesConnector.ts";

export function enqueueDelayedSubmissionProcessingRequest(submissionId: string, delayInSeconds: number): EitherAsync<Error, { submissionProcessingRequestId: string }> {
  return EitherAsync<Error, SendMessageCommandOutput>(() =>
    sqsClient.send(
      new SendMessageCommand({
        MessageBody: JSON.stringify({ submissionID: submissionId }),
        DelaySeconds: delayInSeconds,
        QueueUrl: process.env.SQS_URL,
      }),
    ),
  )
    .map(({ MessageId }) => {
      if (MessageId === undefined) {
        throw new Error("MessageId is undefined");
      }

      return { submissionProcessingRequestId: MessageId };
    })
    .mapLeft((error) => new Error("Failed to enqueue submission processing request", { cause: error }));
}
