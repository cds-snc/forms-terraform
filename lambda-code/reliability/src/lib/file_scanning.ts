import { getFileMetaData } from "./s3FileInput.js";

export class FileScanningCompletionError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "FileScanningCompletionError";
  }
}

export type SubmissionAttachmentWithScanStatus = {
  attachmentPath: string;
  scanStatus: string;
};

export async function getAllSubmissionAttachmentScanStatuses(
  attachmentPaths: string[]
): Promise<SubmissionAttachmentWithScanStatus[]> {
  const submissionAttachmentScanStatusQueries = attachmentPaths.map(async (path) => {
    return getSubmissionAttachmentScanStatus(path).then((status) => {
      console.info(`File ${path} / Scan status: ${JSON.stringify(status)}`);
      return { attachmentPath: path, scanStatus: status };
    });
  });

  return Promise.all(submissionAttachmentScanStatusQueries);
}

async function getSubmissionAttachmentScanStatus(attachmentPath: string): Promise<string> {
  return getFileMetaData(attachmentPath)
    .then((tags) => {
      const guardDutyScanStatus = tags.find(
        (tag) => tag.Key === "GuardDutyMalwareScanStatus"
      )?.Value;

      if (guardDutyScanStatus === undefined) {
        throw new Error(`Detected undefined scan status for file path ${attachmentPath}`);
      }

      return guardDutyScanStatus;
    })
    .catch((error) => {
      throw new Error(`Error retrieving scan status for file: ${(error as Error).message}`);
    });
}
