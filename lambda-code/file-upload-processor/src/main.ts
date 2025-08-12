import { Handler, S3Event, S3EventRecord, SQSEvent } from "aws-lambda";
import {
  extractSubmissionIdFromObjectKey,
  enqueueReliabilityProcessingRequest,
  updateReceiptIdForSubmission,
  retrieveSubmission,
  verifyIfAllFilesExist,
} from "@lib/utils.js";

export const handler: Handler = async (event: SQSEvent) => {
  try {
    const s3ObjectCreatedEvents = event.Records.map(
      (r) => JSON.parse(r.body) as Record<string, unknown>
    )
      // Sometimes S3 will send a "TestEvent" and this protects the lambda from not being able to handle it (see https://docs.aws.amazon.com/AmazonS3/latest/userguide/notification-content-structure.html#notification-content-structure-examples)
      .filter((parsedBody) => parsedBody["Records"] !== undefined)
      .flatMap((parsedBody) => parsedBody["Records"] as S3EventRecord[])
      .filter((s3Record) => s3Record.eventName === "ObjectCreated:Post");

    const submissionIdsWithAssociatedBucketNameToProcess =
      getUniqueSubmissionIdsWithAssociatedBucketNameFromS3ObjectCreatedEvents(
        s3ObjectCreatedEvents
      );

    await requestSubmissionProcessingWhenAllFilesAreAvailable(
      submissionIdsWithAssociatedBucketNameToProcess
    );
  } catch (error) {
    console.error(
      JSON.stringify({
        level: "error",
        msg: "Failed to run file upload processor",
        error: (error as Error).message,
      })
    );

    throw error;
  }
};

function getUniqueSubmissionIdsWithAssociatedBucketNameFromS3ObjectCreatedEvents(
  events: S3EventRecord[]
): { submissionId: string; bucketName: string }[] {
  /**
   * Using a Map in the reduce function to enforce submission identifier uniqueness so that we are not processing the same submission twice during the lambda execution.
   * This can happen if, in the batch of events we received, we have multiple ones associated to the same submission.
   */
  return events
    .reduce((acc, currentEvent) => {
      return acc.set(
        extractSubmissionIdFromObjectKey(currentEvent.s3.object.key),
        currentEvent.s3.bucket.name
      );
    }, new Map<string, string>())
    .entries()
    .map((entry) => ({ submissionId: entry[0], bucketName: entry[1] }))
    .toArray();
}

async function requestSubmissionProcessingWhenAllFilesAreAvailable(
  submissionIdsWithAssociatedBucketName: { submissionId: string; bucketName: string }[]
): Promise<void> {
  const requestSubmissionProcessingWhenAllFilesAreAvailableOperations =
    submissionIdsWithAssociatedBucketName.map(async ({ submissionId, bucketName }) => {
      try {
        const submission = await retrieveSubmission(submissionId);

        if (
          submission === undefined ||
          submission.sendReceipt !== "unknown" ||
          submission.fileKeys === undefined ||
          submission.fileKeys.length === 0
        ) {
          console.info(
            JSON.stringify({
              level: "info",
              message:
                "Skipping processing of file attachments because submission either does not exist or has already been processed or has no attached files",
              submission: submission ?? "undefined",
            })
          );
          return;
        }

        const didReceiveAllAttachedFiles = await verifyIfAllFilesExist(
          submission.fileKeys,
          bucketName
        );

        if (didReceiveAllAttachedFiles) {
          const receiptId = await enqueueReliabilityProcessingRequest(submissionId);

          await updateReceiptIdForSubmission(submissionId, receiptId);

          console.log(
            JSON.stringify({
              level: "info",
              status: "success",
              sqsMessage: receiptId,
              submissionId: submissionId,
            })
          );
        }
      } catch (error) {
        console.error(
          JSON.stringify({
            level: "error",
            severity: 2,
            status: "failed",
            submissionId: submissionId,
            msg: (error as Error).message,
            details: JSON.stringify(error),
          })
        );

        throw error;
      }
    });

  await Promise.all(requestSubmissionProcessingWhenAllFilesAreAvailableOperations);
}
