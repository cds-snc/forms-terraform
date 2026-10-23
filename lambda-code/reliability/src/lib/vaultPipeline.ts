import { enqueueDeferred } from "@gcforms/connectors";
import { EitherAsync } from "purify-ts";
import type { LambdaInvocationContextualLogger } from "../../../common/src/logger/lambdaInvocationContextualLogger.ts";
import { EitherAsyncUtils } from "../main.ts";
import { retrieveSubmissionAttachmentMd5Checksum, retrieveSubmissionAttachmentScanStatus } from "./submissionAttachmentsStorage.ts";
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

type SubmissionAttachmentMetadata = {
  path: string;
  scanStatus: string;
  md5Checksum: string;
};

type SubmissionAttachmentWithNoChecksum = Omit<SubmissionAttachmentMetadata, "md5Checksum">;

export function vaultPipeline(processableSubmission: VaultProcessableSubmission, contextualLogger: LambdaInvocationContextualLogger): EitherAsync<Error, void> {
  if (processableSubmission.attachmentPaths === undefined) {
    return commonVaultPipeline(processableSubmission, contextualLogger);
  } else {
    return handleAttachments(processableSubmission.attachmentPaths, contextualLogger).chain(() => commonVaultPipeline(processableSubmission, contextualLogger));
  }
}

function handleAttachments(attachmentPaths: string[], contextualLogger: LambdaInvocationContextualLogger): EitherAsync<Error, void> {
  return retrieveAllSubmissionAttachmentMetadata(attachmentPaths).ifRight((allSubmissionAttachmentMetadata) => {
    contextualLogger.addMetadata("allSubmissionAttachmentMetadata", JSON.stringify(allSubmissionAttachmentMetadata));
  });
}

function commonVaultPipeline(
  processableSubmission: Omit<VaultProcessableSubmission, "attachmentPaths"> & { attachmentsAsJson?: string },
  contextualLogger: LambdaInvocationContextualLogger,
): EitherAsync<Error, void> {
  return saveSubmissionWithUniqueName({
    submissionId: processableSubmission.id,
    formId: processableSubmission.associatedFormId,
    createdAt: processableSubmission.createdAt,
    language: processableSubmission.language,
    securityAttribute: processableSubmission.securityAttribute,
    version: processableSubmission.version,
    responsesAsJson: processableSubmission.responsesAsJson,
    attachmentsAsJson: processableSubmission.attachmentsAsJson ?? "[]",
    responsesHash: processableSubmission.responsesHash,
  }).chain(() => {
    if (processableSubmission.newSubmissionNotificationId !== undefined) {
      return notifyFormOwnersThatNewSubmissionsAreAvailable(processableSubmission.newSubmissionNotificationId).chainLeft(() => {
        contextualLogger.log({ level: "warn", message: "Failed to notify form owners that new submissions are available" });
        return EitherAsyncUtils.done();
      });
    } else {
      return EitherAsyncUtils.done();
    }
  });
}

function notifyFormOwnersThatNewSubmissionsAreAvailable(notificationId: string): EitherAsync<Error, void> {
  return EitherAsync(() => enqueueDeferred(notificationId)).mapLeft((error) => {
    return new Error("Failed to enqueue deferred notification", { cause: error });
  });
}

function retrieveAllSubmissionAttachmentMetadata(attachmentPaths: string[]): EitherAsync<Error, SubmissionAttachmentMetadata[]> {
  return retrieveAllSubmissionAttachmentScanStatus(attachmentPaths)
    .mapLeft((error) => new Error("Failed to retrieve one or more submission attachment scan statuses", { cause: error }))
    .chain(retrieveAllSubmissionAttachmentChecksum)
    .mapLeft((error) => new Error("Failed to retrieve one or more submission attachment checksums", { cause: error }));
}

function retrieveAllSubmissionAttachmentScanStatus(attachmentPaths: string[]): EitherAsync<Error, SubmissionAttachmentWithNoChecksum[]> {
  return EitherAsync.all(
    attachmentPaths.map((attachmentPath) => {
      return retrieveSubmissionAttachmentScanStatus(attachmentPath).map((scanStatus) => {
        return { path: attachmentPath, scanStatus } satisfies SubmissionAttachmentWithNoChecksum;
      });
    }),
  );
}

function retrieveAllSubmissionAttachmentChecksum(attachments: SubmissionAttachmentWithNoChecksum[]): EitherAsync<Error, SubmissionAttachmentMetadata[]> {
  return EitherAsync.all(
    attachments.map((attachment) => {
      return retrieveSubmissionAttachmentMd5Checksum(attachment.path).map((md5Checksum) => {
        return { ...attachment, md5Checksum } satisfies SubmissionAttachmentMetadata;
      });
    }),
  );
}

// async function verifyAndFlagMaliciousSubmissionAttachments(
//   submissionAttachmentsWithScanStatuses: SubmissionAttachmentInformation[]
// ): Promise<SubmissionAttachmentInformation[]> {
//   return Promise.all(
//     submissionAttachmentsWithScanStatuses.map(async (item) => {
//       try {
//         const attachmentFirst100Bytes = await getObjectFirst100BytesInReliabilityBucket(
//           item.attachmentPath
//         );

//         const isFileValidResult = isFileValid(item.attachmentPath, attachmentFirst100Bytes);

//         // If we flagged the file as invalid we return the same scan status value AWS Guard Duty offers to avoid breaking Data Retrieval API service integration
//         const scanStatus = isFileValidResult ? item.scanStatus : "THREATS_FOUND";

//         return {
//           ...item,
//           scanStatus: scanStatus,
//         };
//       } catch (error) {
//         switch ((error as Error).constructor) {
//           case FileSizeUnder100BytesException:
//             console.warn(
//               JSON.stringify({
//                 level: "warn",
//                 msg: `Will not try to validate file as its size is under 100 bytes and probably contains no content that can be of value to the end user. Flagging ${item.attachmentPath} as potentially malicious.`,
//               })
//             );

//             return {
//               ...item,
//               scanStatus: "THREATS_FOUND",
//             };
//           default: {
//             throw new Error(
//               `Failed to verify submission attachment ${item.attachmentPath}. Reason: ${(error as Error).message}`
//             );
//           }
//         }
//       }
//     })
//   );
// }

// function buildSubmissionAttachmentJsonRecord(
//   submissionAttachmentsWithScanStatuses: SubmissionAttachmentInformation[]
// ): string {
//   return JSON.stringify(
//     submissionAttachmentsWithScanStatuses.map((item) => {
//       const attachmentPathParts = item.attachmentPath.split("/");
//       const attachmentId = attachmentPathParts.at(-2);
//       const attachmentName = attachmentPathParts.at(-1);

//       if (attachmentName === undefined || attachmentId === undefined) {
//         throw new Error(`Attachment name or ID is undefined. File path: ${item.attachmentPath}.`);
//       }

//       return {
//         id: attachmentId,
//         name: attachmentName,
//         path: item.attachmentPath,
//         scanStatus: item.scanStatus,
//         md5: item.md5,
//       };
//     })
//   );
// }
