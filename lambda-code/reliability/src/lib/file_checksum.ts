import type { SubmissionAttachmentWithScanStatus } from "./file_scanning.js";
import { getFileMetaData } from "./s3FileInput.js";

export interface SubmissionAttachmentInformation extends SubmissionAttachmentWithScanStatus {
  md5: string;
}

export const addAllSubmissionAttachmentsChecksums = async (
  attachments: SubmissionAttachmentWithScanStatus[]
): Promise<SubmissionAttachmentInformation[]> => {
  return Promise.all(
    attachments.map(async (record) => {
      const metadata = await getFileMetaData(record.attachmentPath);
      return { ...record, md5: metadata.md5 };
    })
  );
};
