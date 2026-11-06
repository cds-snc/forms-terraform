import { type EmailAttachment, GCNotifyConnector } from "@gcforms/connectors";
import type { FormProperties } from "@gcforms/types";
import { Either, EitherAsync, Left, Right } from "purify-ts";
import { buildEmailMarkdownContent } from "./emailContentBuilder.ts";
import type { Email } from "./formTemplateStorage.ts";
import { markProcessableSubmissionAsProcessedByEmailPipeline } from "./processableSubmissionStorage.ts";
import { retrieveSubmissionAttachementContentAsBase64FromTemporaryStorage } from "./submissionAttachmentsStorage.ts";

export type EmailProcessableSubmission = {
  id: string;
  createdAt: number;
  language: string;
  responsesAsJson: string;
  attachmentPaths?: string[];
};

const gcNotifyConnector = await GCNotifyConnector.defaultUsingApiKeyFromAwsSecret(process.env.NOTIFY_API_KEY ?? "n/a");

export function handleWithEmailPipeline(processableSubmission: EmailProcessableSubmission, formTemplate: FormProperties, email: Email): EitherAsync<Error, void> {
  const { attachmentPaths } = processableSubmission;

  if (attachmentPaths === undefined) {
    return commonHandler(processableSubmission, formTemplate, email);
  } else {
    return retrieveSubmissionAttachmentNamesAndContent(attachmentPaths).chain((emailSubmissionAttachments) => {
      return commonHandler(processableSubmission, formTemplate, email, emailSubmissionAttachments);
    });
  }
}

function commonHandler(
  processableSubmission: Omit<EmailProcessableSubmission, "attachmentPaths">,
  formTemplate: FormProperties,
  email: Email,
  emailAttachments?: EmailAttachment[],
): EitherAsync<Error, void> {
  return EitherAsync
    .liftEither(buildEmailSubjectAndBody(processableSubmission, formTemplate, email)) // biome-ignore format: To help keep the chain vertically aligned
    .chain(({ subject, body }) =>
      EitherAsync<Error, void>(() =>
        gcNotifyConnector.sendEmail(
          email.address,
          {
            templateId: process.env.TEMPLATE_ID ?? "n/a",
            placeholders: { subject, formResponse: body },
            attachments: emailAttachments,
          },
          processableSubmission.id,
        ),
      ),
    )
    .chain(() => markProcessableSubmissionAsProcessedByEmailPipeline(processableSubmission.id));
}

function retrieveSubmissionAttachmentNamesAndContent(attachmentPaths: string[]): EitherAsync<Error, EmailAttachment[]> {
  return EitherAsync.all(
    attachmentPaths.map((attachmentPath) => {
      return EitherAsync
        .liftEither(getAttachmentNameFromPath(attachmentPath)) // biome-ignore format: To help keep the chain vertically aligned
        .chain((attachmentName) => {
          return retrieveSubmissionAttachementContentAsBase64FromTemporaryStorage(attachmentPath).map((contentAsBase64) => {
            return { fileName: attachmentName, base64EncodedFile: contentAsBase64 } satisfies EmailAttachment;
          });
        });
    }),
  ).mapLeft((error) => new Error("Failed to retrieve submission attachment names and content", { cause: error }));
}

function getAttachmentNameFromPath(attachmentPath: string): Either<Error, string> {
  const attachmentName = attachmentPath.split("/").pop();

  if (attachmentName === undefined) {
    return Left(new Error("attachmentName is undefined"));
  }

  return Right(attachmentName);
}

function buildEmailSubjectAndBody(
  processableSubmission: Omit<EmailProcessableSubmission, "attachmentPaths">,
  formTemplate: FormProperties,
  email: Email,
): Either<Error, { subject: string; body: string }> {
  return Either.encase(() => {
    const subject = processableSubmission.language === "fr" ? (email.subjectFr ?? formTemplate.titleFr) : (email.subjectEn ?? formTemplate.titleEn);
    const body = buildEmailMarkdownContent({
      emailSubject: subject,
      formTemplate: formTemplate,
      submission: {
        id: processableSubmission.id,
        createdAt: processableSubmission.createdAt,
        language: processableSubmission.language,
        responsesAsJson: processableSubmission.responsesAsJson,
      },
    });

    return { subject, body };
  });
}
