// import { getFileTags } from "./s3FileInput.js";

import { EitherAsync } from "purify-ts";
import { retrieveSubmissionAttachmentScanStatus } from "./submissionAttachmentsStorage.ts";

export type SubmissionAttachmentWithScanStatus = {
  attachmentPath: string;
  scanStatus: string;
};

export type SubmissionAttachmentWithScanStatusAndChecksum = {
  md5Checksum: string;
};

export function retrieveSubmissionAttachmentScanStatuses(attachmentPaths: string[]): EitherAsync<Error, SubmissionAttachmentWithScanStatus[]> {
  return EitherAsync.all(
    attachmentPaths.map((attachmentPath) => {
      return retrieveSubmissionAttachmentScanStatus(attachmentPath).map((scanStatus) => {
        return { attachmentPath, scanStatus } satisfies SubmissionAttachmentWithScanStatus;
      });
    }),
  );
}

export function retrieveSubmissionAttachmentChecksums(attachmentPaths: string[]): EitherAsync<Error, SubmissionAttachmentWithChecksum[]> {
  return EitherAsync.all(
    attachmentPaths.map((attachmentPath) => {
      return retrieveSubmissionAttachmentScanStatus(attachmentPath).map((scanStatus) => {
        return { md5Checksum } satisfies SubmissionAttachmentWithChecksum;
      });
    }),
  );
}

// export const addAllSubmissionAttachmentsChecksums = async (
//   attachments: SubmissionAttachmentWithScanStatus[]
// ): Promise<SubmissionAttachmentInformation[]> => {
//   return Promise.all(
//     attachments.map(async (record) => {
//       // Not throwing an error if md5 metadata is missing for backwards compatibility
//       const metadata = await getFileMetaData(record.attachmentPath);
//       return { ...record, md5: metadata.md5 };
//     })
//   );
// };
