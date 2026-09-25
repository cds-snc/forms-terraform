import { enqueueDeferred } from "@gcforms/connectors";
import { EitherAsyncUtils, type LambdaInvocationContextualLogger } from "common";
import { Either, EitherAsync, Right } from "purify-ts";
import { isFileValid } from "./fileValidation.ts";
import { deleteProcessableSubmission } from "./processableSubmissionStorage.ts";
import {
  copySubmissionAttachmentsFromTemporaryToPermanentStorage,
  deleteSubmissionAttachmentsFromTemporaryStorage,
  retrieveSubmissionAttachmentFirst100BytesFromTemporaryStorage,
  retrieveSubmissionAttachmentMd5ChecksumFromTemporaryStorage,
  retrieveSubmissionAttachmentScanStatusFromTemporaryStorage,
} from "./submissionAttachmentsStorage.ts";
import { saveSubmissionWithUniqueName } from "./submissionStorage.ts";

export type VaultProcessableSubmission = {
  id: string;
  associatedFormId: string;
  createdAt: number;
  language: string;
  securityAttribute: string;
  version: number;
  responsesAsJson: string;
  responsesHash: string;
  attachmentPaths?: string[];
  newSubmissionNotificationId?: string;
};

type ValidatedSubmissionAttachment = {
  path: string;
  scanStatus: string;
  md5Checksum: string;
};

type SubmissionAttachmentWithTemporaryScanStatus = Omit<ValidatedSubmissionAttachment, "scanStatus" | "md5Checksum"> & {
  temporaryScanStatus: string;
};

type SubmissionAttachmentWithChecksum = SubmissionAttachmentWithTemporaryScanStatus & {
  md5Checksum: string;
};

export function handleWithVaultPipeline(processableSubmission: VaultProcessableSubmission, contextualLogger: LambdaInvocationContextualLogger): EitherAsync<Error, void> {
  const { attachmentPaths } = processableSubmission;

  if (attachmentPaths === undefined) {
    return commonHandler(processableSubmission, contextualLogger);
  } else {
    return retrieveSubmissionAttachmentScanStatuses(attachmentPaths)
      .chain(retrieveSubmissionAttachmentChecksums)
      .ifRight((submissionAttachmentsPreValidation) => {
        contextualLogger.addMetadata("submissionAttachmentsPreValidation", JSON.stringify(submissionAttachmentsPreValidation));
      })
      .chain(validateSubmissionAttachmentsAndDetermineFinalScanStatuses)
      .ifRight((submissionAttachmentsPostValidation) => {
        contextualLogger.addMetadata("submissionAttachmentsPostValidation", JSON.stringify(submissionAttachmentsPostValidation));
      })
      .chain((validatedSubmissionAttachments) => copySubmissionAttachmentsFromTemporaryToPermanentStorage(attachmentPaths).map(() => ({ validatedSubmissionAttachments })))
      .chain(({ validatedSubmissionAttachments }) => EitherAsync.liftEither(serializeSubmissionAttachmentsToJson(validatedSubmissionAttachments)))
      .chain((submissionAttachmentsAsJson) => commonHandler(processableSubmission, contextualLogger, submissionAttachmentsAsJson))
      .chain(() =>
        EitherAsyncUtils.rightOnLeft(deleteSubmissionAttachmentsFromTemporaryStorage(attachmentPaths), (error) =>
          contextualLogger.log({ level: "warn", message: "Failed to clean up processable submission associated attachments", error }),
        ),
      );
  }
}

function commonHandler(
  processableSubmission: Omit<VaultProcessableSubmission, "attachmentPaths">,
  contextualLogger: LambdaInvocationContextualLogger,
  submissionAttachmentsAsJson?: string,
): EitherAsync<Error, void> {
  return saveSubmissionWithUniqueName({
    submissionId: processableSubmission.id,
    formId: processableSubmission.associatedFormId,
    createdAt: processableSubmission.createdAt,
    language: processableSubmission.language,
    securityAttribute: processableSubmission.securityAttribute,
    version: processableSubmission.version,
    responsesAsJson: processableSubmission.responsesAsJson,
    attachmentsAsJson: submissionAttachmentsAsJson ?? "[]",
    responsesHash: processableSubmission.responsesHash,
  })
    .chain(() =>
      processableSubmission.newSubmissionNotificationId !== undefined
        ? EitherAsyncUtils.rightOnLeft(notifyFormOwnersThatNewSubmissionsAreAvailable(processableSubmission.newSubmissionNotificationId), (error) =>
            contextualLogger.log({ level: "warn", message: "Failed to notify form owners that new submissions are available", error }),
          )
        : EitherAsyncUtils.right(),
    )
    .chain(() =>
      EitherAsyncUtils.rightOnLeft(deleteProcessableSubmission(processableSubmission.id), (error) =>
        contextualLogger.log({ level: "warn", message: "Failed to clean up processable submission", error }),
      ),
    );
}

function notifyFormOwnersThatNewSubmissionsAreAvailable(notificationId: string): EitherAsync<Error, void> {
  return EitherAsync(() => enqueueDeferred(notificationId)).mapLeft((error) => new Error("Failed to enqueue deferred notification", { cause: error }));
}

function retrieveSubmissionAttachmentScanStatuses(attachmentPaths: string[]): EitherAsync<Error, SubmissionAttachmentWithTemporaryScanStatus[]> {
  return EitherAsync.all(
    attachmentPaths.map((attachmentPath) => {
      return retrieveSubmissionAttachmentScanStatusFromTemporaryStorage(attachmentPath).map((scanStatus) => {
        return { path: attachmentPath, temporaryScanStatus: scanStatus } satisfies SubmissionAttachmentWithTemporaryScanStatus;
      });
    }),
  ).mapLeft((error) => new Error("Failed to retrieve submission attachment scan statuses", { cause: error }));
}

function retrieveSubmissionAttachmentChecksums(attachments: SubmissionAttachmentWithTemporaryScanStatus[]): EitherAsync<Error, SubmissionAttachmentWithChecksum[]> {
  return EitherAsync.all(
    attachments.map((attachment) => {
      return retrieveSubmissionAttachmentMd5ChecksumFromTemporaryStorage(attachment.path).map((md5Checksum) => {
        return { ...attachment, md5Checksum } satisfies SubmissionAttachmentWithChecksum;
      });
    }),
  ).mapLeft((error) => new Error("Failed to retrieve submission attachment checksums", { cause: error }));
}

function validateSubmissionAttachmentsAndDetermineFinalScanStatuses(attachments: SubmissionAttachmentWithChecksum[]): EitherAsync<Error, ValidatedSubmissionAttachment[]> {
  return EitherAsync.all(
    attachments.map((attachment) => {
      return retrieveSubmissionAttachmentFirst100BytesFromTemporaryStorage(attachment.path)
        .chain((maybeFirst100Bytes) => {
          return maybeFirst100Bytes.caseOf({
            Just: (first100Bytes) => EitherAsync.liftEither(isFileValid(attachment.path, first100Bytes)),
            Nothing: () => EitherAsync.liftEither(Right(false)),
          });
        })
        .map((isFileValid) => {
          return {
            ...attachment,
            scanStatus: isFileValid ? attachment.temporaryScanStatus : "THREATS_FOUND", // Follow AWS Guard Duty scan result status values https://docs.aws.amazon.com/guardduty/latest/ug/monitoring-malware-protection-s3-scans-gdu.html#s3-object-scan-result-value-malware-protection
          } satisfies ValidatedSubmissionAttachment;
        });
    }),
  ).mapLeft((error) => new Error("Failed to validate submission attachments and determine final scan statuses", { cause: error }));
}

function serializeSubmissionAttachmentsToJson(attachments: ValidatedSubmissionAttachment[]): Either<Error, string> {
  return Either.encase(() =>
    JSON.stringify(
      attachments.map((attachment) => {
        const attachmentPathParts = attachment.path.split("/");
        const attachmentId = attachmentPathParts.at(-2);
        const attachmentName = attachmentPathParts.at(-1);

        if (attachmentName === undefined || attachmentId === undefined) {
          throw new Error(`Attachment name or ID is undefined. Attachment path: ${attachment.path}.`);
        }

        return {
          id: attachmentId,
          name: attachmentName,
          path: attachment.path,
          scanStatus: attachment.scanStatus,
          md5: attachment.md5Checksum,
        };
      }),
    ),
  ).mapLeft((error) => new Error("Failed to serialize submission attachments to JSON", { cause: error }));
}
