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
    const s3ObjectCreatedEvents = event.Records.flatMap((sqsRecord) => {
      return (JSON.parse(sqsRecord.body) as S3Event).Records;
    }).filter((s3Record) => s3Record.eventName === "ObjectCreated:Post"); // Sometimes S3 will send a "TestEvent" and this protects the lambda from throwing a type error

    const submissionIdsToProcess =
      getUniqueSubmissionIdsFromS3ObjectCreatedEvents(s3ObjectCreatedEvents);

    await requestSubmissionProcessingWhenAllFilesAreAvailable(submissionIdsToProcess);
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

function getUniqueSubmissionIdsFromS3ObjectCreatedEvents(events: S3EventRecord[]): string[] {
  /**
   * Creating a Set of submission identifiers from the array of events in order to exclude duplicate values and make sure we are not processing the same submission twice during the lambda execution.
   * This can happen if, in the batch of events we received, we have multiple ones associated to the same submission.
   */
  return new Set(events.map((event) => extractSubmissionIdFromObjectKey(event.s3.object.key)))
    .values()
    .toArray();
}

async function requestSubmissionProcessingWhenAllFilesAreAvailable(
  submissionIds: string[]
): Promise<void> {
  const requestSubmissionProcessingWhenAllFilesAreAvailableOperations = submissionIds.map(
    async (submissionId) => {
      try {
        const submission = await retrieveSubmission(submissionId);

        // If there are no files to verify or the submission has already been processed (sendReceipt != unknown) return early
        if (
          submission.sendReceipt !== "unknown" ||
          submission.fileKeys === undefined ||
          submission.fileKeys.length === 0
        ) {
          return;
        }

        const didReceiveAllAttachedFiles = await verifyIfAllFilesExist(submission.fileKeys);

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
    }
  );

  await Promise.all(requestSubmissionProcessingWhenAllFilesAreAvailableOperations);
}
