import { lambdaWithSqsBatchProcessingAndContextualLogger } from "common";
import { EitherAsync, Right } from "purify-ts";
import { type ProcessableSubmission, retrieveProcessableSubmissionFromReliabilityStorage } from "./lib/reliabilityStorage.ts";

type LambdaSqsRecordBody = {
  submissionID: string;
};

// What we want to do here? Export to common package? Not use at all?
export const EitherAsyncUtils = {
  done: (): EitherAsync<Error, void> => EitherAsync.liftEither(Right(undefined)),
};

export const handler = lambdaWithSqsBatchProcessingAndContextualLogger<LambdaSqsRecordBody>(({ event, contextualLogger }) => {
  contextualLogger.addMetadata("submissionId", event.submissionID);

  return retrieveProcessableSubmissionFromReliabilityStorage(event.submissionID)
    .chain((processableSubmissionOrNull) => {
      const result = processableSubmissionOrNull.extract();

      // Check if form data exists or was already processed.
      if (result === null || result.notifyProcessed === true) {
        // Ack and remove message from queue if it doesn't exist in the DB
        // Do not throw an error so it does not retry again
        contextualLogger.log({
          level: "warn",
          message: `Submission will not be processed because ${result === null ? "it could not be found in the database" : "it has already been processed by the email delivery flow"}`,
        });

        return EitherAsyncUtils.done();
      }

      return handleProcessableSubmission(result);
    })
    .ifRight(() =>
      contextualLogger.log({
        level: "info",
        message: "Submission processed successfully",
      }),
    )
    .ifLeft((error) =>
      contextualLogger.log({
        level: "error",
        message: "Submission processing failed",
        error: error as Error,
        severityLevel: "2",
        // sendReceipt: sendReceipt ?? "n/a",
      }),
    );
});

function handleProcessableSubmission(processableSubmission: ProcessableSubmission): EitherAsync<Error, void> {
  return EitherAsync.fromPromise(() => Promise.resolve(Right(undefined)));
}
