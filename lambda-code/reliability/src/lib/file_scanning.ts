import { getFileTags } from "./s3FileInput.js";

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

  const statuses = await Promise.all(submissionAttachmentScanStatusQueries);
  if (haveAllSubmissionAttachmentsBeenScanned(statuses)) {
    return statuses;
  } else {
    throw new FileScanningCompletionError(`File scanning is not completed.`);
  }
}

export function haveAllSubmissionAttachmentsBeenScanned(
  attachmentsWithScanStatuses: { attachmentPath: string; scanStatus: string | undefined }[]
): attachmentsWithScanStatuses is SubmissionAttachmentWithScanStatus[] {
  return attachmentsWithScanStatuses.every((item) => item.scanStatus !== undefined);
}

async function getSubmissionAttachmentScanStatus(
  attachmentPath: string
): Promise<string | undefined> {
  return getFileTags(attachmentPath)
    .then((tags) => {
      return tags.find((tag) => tag.Key === "GuardDutyMalwareScanStatus")?.Value;
    })
    .catch((error) => {
      throw new Error(`Error retrieving scan status for file: ${(error as Error).message}`);
    });
}
