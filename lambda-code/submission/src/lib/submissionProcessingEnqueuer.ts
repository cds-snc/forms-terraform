import { SendMessageCommand, type SendMessageCommandOutput } from "@aws-sdk/client-sqs";
import { EitherAsync } from "purify-ts";
import { sqsClient } from "./awsServicesConnector.ts";

const SUBMISSION_PROCESSING_REQUEST_DELAY_IN_SECONDS = 5;

export function enqueueDelayedSubmissionProcessingRequest(submissionId: string): EitherAsync<Error, { submissionProcessingRequestId: string }> {
  return EitherAsync<Error, SendMessageCommandOutput>(() =>
    sqsClient.send(
      new SendMessageCommand({
        MessageBody: JSON.stringify({ submissionID: submissionId }),
        DelaySeconds: SUBMISSION_PROCESSING_REQUEST_DELAY_IN_SECONDS,
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
    .mapLeft((error) => new Error("Failed to enqueue delayed submission processing request", { cause: error }));
}
