import type { SubmissionAttachmentWithScanStatus } from "./file_scanning.ts";
import { getFileMetaData } from "./s3FileInput.ts";

export interface SubmissionAttachmentInformation extends SubmissionAttachmentWithScanStatus {
  md5?: string;
}

export const addAllSubmissionAttachmentsChecksums = async (
  attachments: SubmissionAttachmentWithScanStatus[]
): Promise<SubmissionAttachmentInformation[]> => {
  return Promise.all(
    attachments.map(async (record) => {
      // Not throwing an error if md5 metadata is missing for backwards compatibility
      const metadata = await getFileMetaData(record.attachmentPath);
      return { ...record, md5: metadata.md5 };
    })
  );
};
