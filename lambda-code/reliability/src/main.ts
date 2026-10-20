import { type LambdaInvocationContextualLogger, lambdaWithSqsBatchProcessingAndContextualLogger } from "common";
import { EitherAsync, Left, Right } from "purify-ts";
import { type FormTemplate, retrieveFormTemplate } from "./lib/formTemplateStorage.ts";
import { markProcessableSubmissionForDeletionIn30days, type ProcessableSubmission, retrieveProcessableSubmission } from "./lib/processableSubmissionStorage.ts";
import { retrieveSubmissionAttachmentScanStatus } from "./lib/submissionAttachmentsStorage.ts";

type LambdaSqsRecordBody = {
  submissionID: string;
};

// What we want to do here? Export to common package? Not use at all?
export const EitherAsyncUtils = {
  done: (): EitherAsync<Error, void> => EitherAsync.liftEither(Right(undefined)),
  error: (message: string): EitherAsync<Error, void> => EitherAsync.liftEither(Left(new Error(message))),
};

export const handler = lambdaWithSqsBatchProcessingAndContextualLogger<LambdaSqsRecordBody>(({ event, contextualLogger }) => {
  contextualLogger.addMetadata("submissionId", event.submissionID);

  return retrieveProcessableSubmission(event.submissionID)
    .chain((processableSubmission) => {
      return processableSubmission.caseOf({
        Just: (pSubmission) => {
          if (pSubmission.notifyProcessed) {
            return skipProcessing("Skipping regular processing as submission has already been sent via GC Notify (email delivery pipeline)", contextualLogger);
          }

          return retrieveFormTemplate(pSubmission.associatedFormId).chain((formTemplate) => {
            return formTemplate.caseOf({
              Just: (fTemplate) => {
                if (fTemplate.isFormArchived) {
                  return markProcessableSubmissionForDeletionIn30days(pSubmission.id).chain(() =>
                    skipProcessing(
                      "Skipping regular processing because the form associated with this submission has been archived. Submission has been marked for deletion (in 30 days).",
                      contextualLogger,
                    ),
                  );
                }

                return handleSubmission(pSubmission, fTemplate, contextualLogger);
              },
              Nothing: () => EitherAsyncUtils.error("Form template could not be found in the database"),
            });
          });
        },
        Nothing: () => skipProcessing("Skipping regular processing as submission could not be found in the database", contextualLogger),
      });
    })
    .ifRight(() =>
      contextualLogger.log({
        level: "info",
        message: "Submission processing completed",
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

function skipProcessing(reason: string, contextualLogger: LambdaInvocationContextualLogger): EitherAsync<Error, void> {
  contextualLogger.log({
    level: "warn",
    message: reason,
  });

  return EitherAsyncUtils.done();
}

function handleSubmission(processableSubmission: ProcessableSubmission, formTemplate: FormTemplate, contextualLogger: LambdaInvocationContextualLogger): EitherAsync<Error, void> {
  return EitherAsyncUtils.done();
}

/**
 *
 * should look like this in Vault
 *
 * [{"id":"d2d131bc-17bf-4e05-9296-234f140fd417","name":"Screenshot 2026-09-28 at 11.09.16 AM.png","path":"form_attachments/2026-10-05/5c59f2e3-5e72-4793-af62-cb59304331a3/d2d131bc-17bf-4e05-9296-234f140fd417/Screenshot 2026-09-28 at 11.09.16 AM.png","scanStatus":"NO_THREATS_FOUND","md5":"f52d6dc56c21e2bad35dc7d8c7342cb6"}]
 */
