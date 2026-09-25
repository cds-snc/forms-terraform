import { EitherAsyncUtils, type LambdaInvocationContextualLogger, lambdaWithSqsBatchProcessingAndContextualLogger } from "common";
import type { EitherAsync } from "purify-ts";
import { handleWithEmailPipeline } from "./lib/emailPipeline.ts";
import { type Form, retrieveForm } from "./lib/formTemplateStorage.ts";
import { markProcessableSubmissionForDeletionIn30days, type ProcessableSubmission, retrieveProcessableSubmission } from "./lib/processableSubmissionStorage.ts";
import { handleWithVaultPipeline } from "./lib/vaultPipeline.ts";

type LambdaSqsRecordBody = {
  submissionID: string;
};

export const handler = lambdaWithSqsBatchProcessingAndContextualLogger<LambdaSqsRecordBody>(({ event, contextualLogger }) => {
  contextualLogger.addMetadata("submissionId", event.submissionID);

  return retrieveProcessableSubmission(event.submissionID)
    .chain((maybeProcessableSubmission) => {
      return maybeProcessableSubmission.caseOf({
        Just: (processableSubmission) => {
          if (processableSubmission.hasBeenSuccessfullyProcessedByEmailPipeline) {
            return skipProcessing("Skipping regular processing as submission has already been processed by the email pipeline", contextualLogger);
          }

          return retrieveForm(processableSubmission.associatedFormId).chain((maybeForm) => {
            return maybeForm.caseOf({
              Just: (form) => {
                if (form.isArchived) {
                  return markProcessableSubmissionForDeletionIn30days(processableSubmission.id).chain(() =>
                    skipProcessing(
                      "Skipping regular processing because the form associated with this submission has been archived. Submission has been marked for deletion (in 30 days).",
                      contextualLogger,
                    ),
                  );
                }

                return handleProcessableSubmission(processableSubmission, form, contextualLogger);
              },
              Nothing: () => EitherAsyncUtils.left(new Error("Form template could not be found in the database")),
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
      }),
    );
});

function skipProcessing(reason: string, contextualLogger: LambdaInvocationContextualLogger): EitherAsync<Error, void> {
  contextualLogger.log({
    level: "warn",
    message: reason,
  });

  return EitherAsyncUtils.right();
}

function handleProcessableSubmission(processableSubmission: ProcessableSubmission, form: Form, contextualLogger: LambdaInvocationContextualLogger): EitherAsync<Error, void> {
  const attachmentPaths: string[] | undefined = processableSubmission.attachmentPathsAsJson ? JSON.parse(processableSubmission.attachmentPathsAsJson) : undefined;

  if (form.deliveryMethod.type === "vault") {
    return handleWithVaultPipeline(
      {
        id: processableSubmission.id,
        associatedFormId: processableSubmission.associatedFormId,
        createdAt: processableSubmission.createdAt,
        language: processableSubmission.language,
        securityAttribute: processableSubmission.securityAttribute,
        version: processableSubmission.version,
        responsesAsJson: processableSubmission.responsesAsJson,
        responsesHash: processableSubmission.responsesHash,
        attachmentPaths,
        newSubmissionNotificationId: processableSubmission.notificationId,
      },
      contextualLogger,
    ).ifRight(() => contextualLogger.log({ level: "info", message: "Submission was successfully saved to the Vault" }));
  } else {
    return handleWithEmailPipeline(
      {
        id: processableSubmission.id,
        associatedFormId: processableSubmission.associatedFormId,
        createdAt: processableSubmission.createdAt,
        language: processableSubmission.language,
        responsesAsJson: processableSubmission.responsesAsJson,
        attachmentPaths,
      },
      contextualLogger,
    ).ifRight(() => contextualLogger.log({ level: "info", message: "Submission was successfully sent by email" }));
  }
}
