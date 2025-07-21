import { Handler, S3Event, SQSEvent } from "aws-lambda";
import {
  retrieveSubmissionId,
  enqueueReliabilityProcessingRequest,
  updateReceiptIdForSubmission,
  getFileKeysForSubmission,
  verifyIfAllFilesExist,
} from "@lib/utils.js";

export const handler: Handler = async (sqsMessages: SQSEvent) => {
  const s3Events = sqsMessages.Records.flatMap(
    (sqsMessage) => (JSON.parse(sqsMessage.body) as S3Event).Records
  );

  const eventMap = new Map<string, { submissionId: string; bucketName: string }>();

  // Only verify each submissionID once
  s3Events.forEach((event) => {
    // Sometimes S3 will send a test event and this protects the lambda from throwing a type error
    if (event) {
      const { submissionId, bucketName } = retrieveSubmissionId(event);
      eventMap.set(submissionId, { submissionId, bucketName });
    }
  });

  const eventArray = Array.from(eventMap.values());

  await Promise.all(
    eventArray.map(async ({ submissionId, bucketName }) => {
      try {
        const expectedFileKeys = await getFileKeysForSubmission(submissionId);

        // If there are no files to verify or the submission has already been processed return early
        if (expectedFileKeys.length === 0) {
          return;
        }

        const allProcessed = await verifyIfAllFilesExist(expectedFileKeys, bucketName);

        if (allProcessed) {
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
    })
  );
};
