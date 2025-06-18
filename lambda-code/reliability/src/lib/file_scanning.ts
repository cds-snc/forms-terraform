import { getFileMetaData } from "./s3FileInput.js";

export class FileScanningCompletionError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "FileScanningCompletionError";
  }
}

export type SubmissionAttachmentWithScanStatus = {
  attachmentPath: string;
  scanStatus: string | undefined;
};

export function getAllSubmissionAttachmentScanStatuses(
  attachmentPaths: string[]
): Promise<SubmissionAttachmentWithScanStatus[]> {
  const submissionAttachmentScanStatusQueries = attachmentPaths.map((path) => {
    return getSubmissionAttachmentScanStatus(path).then((status) => {
      console.info(`File ${path} / Scan status: ${JSON.stringify(status)}`);
      return { attachmentPath: path, scanStatus: status };
    });
  });

  return Promise.all(submissionAttachmentScanStatusQueries);
}

export function haveAllSubmissionAttachmentsBeenScanned(
  attachmentsWithScanStatuses: SubmissionAttachmentWithScanStatus[]
) {
  return attachmentsWithScanStatuses.every((item) => item.scanStatus !== undefined);
}

function getSubmissionAttachmentScanStatus(attachmentPath: string): Promise<string | undefined> {
  return getFileMetaData(attachmentPath)
    .then((tags) => {
      return tags.find((tag) => tag.Key === "GuardDutyMalwareScanStatus")?.Value;
    })
    .catch((error) => {
      console.error(`Error retrieving scan status for file: ${(error as Error).message}`);
      return undefined;
    });
}
