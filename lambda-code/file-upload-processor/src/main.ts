import { Handler, S3Event } from "aws-lambda";
import {
  retrieveSubmissionId,
  enqueueReliabilityProcessingRequest,
  updateReceiptIdForSubmission,
  getFileKeysForSubmission,
  verifyIfAllFilesExist,
} from "@lib/utils.js";

export const handler: Handler = async (uploadEvent: S3Event) => {
  try {
    // get the submisison Id from the object key
    const { submissionId, bucketName } = retrieveSubmissionId(uploadEvent.Records[0]);

    const expectedFileKeys = await getFileKeysForSubmission(submissionId);

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
        severity: 1, // this will trigger an alert to on-call team
        status: "failed",
        submissionId: uploadEvent.Records[0].s3.object.key,
        msg: (error as Error).message,
        details: JSON.stringify(error),
      })
    );
  }
};
