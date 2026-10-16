import { type LambdaInvocationContextualLogger, lambdaWithSqsBatchProcessingAndContextualLogger } from "common";
import { EitherAsync, Right } from "purify-ts";
import { retrieveFormTemplate } from "./lib/formTemplateStorage.ts";
import { type ProcessableSubmission, retrieveProcessableSubmission } from "./lib/processableSubmissionStorage.ts";

type LambdaSqsRecordBody = {
  submissionID: string;
};

// What we want to do here? Export to common package? Not use at all?
export const EitherAsyncUtils = {
  done: (): EitherAsync<Error, void> => EitherAsync.liftEither(Right(undefined)),
};

export const handler = lambdaWithSqsBatchProcessingAndContextualLogger<LambdaSqsRecordBody>(({ event, contextualLogger }) => {
  contextualLogger.addMetadata("submissionId", event.submissionID);

  return retrieveProcessableSubmission(event.submissionID)
    .chain((processableSubmission) => {
      return processableSubmission.caseOf({
        Just: (value) => handleProcessableSubmission(value, contextualLogger),
        Nothing: () => {
          contextualLogger.log({
            level: "warn",
            message: "Skipping regular processing as submission could not be found in the database",
          });

          return EitherAsyncUtils.done();
        },
      });
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

function handleProcessableSubmission(processableSubmission: ProcessableSubmission, contextualLogger: LambdaInvocationContextualLogger): EitherAsync<Error, void> {
  if (processableSubmission.notifyProcessed) {
    contextualLogger.log({
      level: "warn",
      message: "Skipping regular processing as submission has already been sent via GC Notify (email delivery pipeline)",
    });

    return EitherAsyncUtils.done();
  }

  return retrieveFormTemplate(processableSubmission.id)
    .chain((formTemplate) => {
      return formTemplate.caseOf({
        Just: (value) => {
          if (value.isFormArchived) {
            return markSubmissionForDeletionIn30Days();
          }

          return getAllSubmissionAttachmentScanStatuses();
        },
        Nothing: () => {
          throw new Error("Form template could not be found in the database");
        },
      });
    })
    .chain(addAllSubmissionAttachmentsChecksums)
    .chain(() => {
      return sendToNotify();
    });
}

function markSubmissionForDeletionIn30Days(): EitherAsync<Error, void> {
  return EitherAsyncUtils.done();
}

function getAllSubmissionAttachmentScanStatuses(): EitherAsync<Error, void> {
  return EitherAsyncUtils.done();
}

function addAllSubmissionAttachmentsChecksums(): EitherAsync<Error, void> {
  return EitherAsyncUtils.done();
}

function sendToNotify(): EitherAsync<Error, void> {
  return EitherAsyncUtils.done();
}

function sendToVault(): EitherAsync<Error, void> {
  return EitherAsyncUtils.done();
}
