import { Handler } from "aws-lambda";
import {
  getUnprocessedSubmissions,
  decideIfUnprocessedSubmissionShouldBeDeleted,
  deleteUnprocessedSubmission,
  ReasonBehindUnprocessedSubmission,
} from "@lib/datalayer.js";

export const handler: Handler = async () => {
  try {
    await cleanupIncompleteSubmissionsWithFileAttachments();
  } catch (error) {
    console.error(
      JSON.stringify({
        level: "error",
        msg: "Failed to run file upload cleanup process",
        error: (error as Error).message,
      })
    );

    throw error;
  }
};

async function cleanupIncompleteSubmissionsWithFileAttachments(): Promise<void> {
  let isOperationComplete = false;
  let lastEvaluatedKey: Record<string, any> | undefined = undefined;

  while (isOperationComplete === false) {
    const { unprocessedSubmissions, lastEvaluatedKey: lastReturnedEvaluatedKey } =
      await getUnprocessedSubmissions(lastEvaluatedKey);

    const detectAndDeleteOperations = unprocessedSubmissions.map(async (unprocessedSubmission) => {
      const { shouldDelete, reason } = await decideIfUnprocessedSubmissionShouldBeDeleted(
        unprocessedSubmission
      );

      switch (reason) {
        case ReasonBehindUnprocessedSubmission.SubmissionIsInReliabilityQueue:
          console.error(
            JSON.stringify({
              level: "error",
              severity: 2,
              submissionId: unprocessedSubmission.submissionId,
              msg: "Possible issue with Reliability Queue processing",
              details: `Submission ${
                unprocessedSubmission.submissionId
              } has been sent into the Reliabilty Queue but has not been processed in over ${Math.floor(
                (Date.now() - unprocessedSubmission.createdAt) / 3600000
              )} hours`,
            })
          );
          break;
        case ReasonBehindUnprocessedSubmission.SubmissionHasAllAttachedFiles:
          console.error(
            JSON.stringify({
              level: "error",
              severity: 2,
              submissionId: unprocessedSubmission.submissionId,
              msg: "Possible issue with File Upload processing",
              details: `Submission ${
                unprocessedSubmission.submissionId
              } has been successfully uploaded but not processed by the File Processing lambda in over ${Math.floor(
                (Date.now() - unprocessedSubmission.createdAt) / 3600000
              )} hours`,
            })
          );
          break;
        default:
          break;
      }

      if (shouldDelete) {
        await deleteUnprocessedSubmission(unprocessedSubmission);

        console.info(
          `Deleted partially completed submission ID ${unprocessedSubmission.submissionId} and associated Files`
        );
      }
    });

    const detectAndDeleteOperationsResults = await Promise.allSettled(detectAndDeleteOperations);

    detectAndDeleteOperationsResults.forEach((result) => {
      if (result.status === "rejected") {
        console.error(result.reason);
      }
    });

    if (lastReturnedEvaluatedKey !== undefined) {
      lastEvaluatedKey = lastReturnedEvaluatedKey;
    } else {
      isOperationComplete = true;
    }
  }
}
