import { saveToVault, removeSubmission } from "./dataLayer.js";
import { SubmissionAttachmentWithScanStatus } from "./file_scanning.js";
import {
  copyFilesFromReliabilityToVaultStorage,
  removeFilesFromReliabilityStorage,
} from "./s3FileInput.js";
import { FormSubmission } from "./types.js";

export default async (
  submissionID: string,
  sendReceipt: string,
  formSubmission: FormSubmission,
  submissionAttachmentsWithScanStatuses: SubmissionAttachmentWithScanStatus[],
  formID: string,
  language: string,
  createdAt: string,
  securityAttribute: string,
  formSubmissionHash: string
) => {
  const submissionAttachmentPaths = submissionAttachmentsWithScanStatuses.map(
    (item) => item.attachmentPath
  );

  const submissionAttachments = submissionAttachmentsWithScanStatuses.map((item) => {
    if (item.scanStatus === undefined) {
      // This should never happen since we verified earlier whether file scanning has completed
      throw new Error(`Detected undefined scan status for file path ${item.attachmentPath}`);
    }

    const attachmentPathParts = item.attachmentPath.split("/");

    const attachmentName = attachmentPathParts.at(-1);

    const attachmentId = attachmentPathParts.at(-2);

    if (attachmentName === undefined) {
      throw new Error(`Attachment name is undefined. File path: ${item.attachmentPath}.`);
    }

    return {
      id: attachmentId,
      name: attachmentName,
      path: item.attachmentPath,
      scanStatus: item.scanStatus,
    };
  });

  try {
    await copyFilesFromReliabilityToVaultStorage(submissionAttachmentPaths);
    await saveToVault(
      submissionID,
      formSubmission.responses,
      JSON.stringify(submissionAttachments),
      formID,
      language,
      createdAt,
      securityAttribute,
      formSubmissionHash
    );
  } catch (error) {
    console.error(
      JSON.stringify({
        level: "error",
        severity: 2,
        submissionId: submissionID,
        sendReceipt: sendReceipt,
        msg: "Failed to save submission to Vault.",
        error: (error as Error).message,
      })
    );
    throw new Error(`Failed to save submission to Vault.`);
  }

  try {
    await Promise.all([
      removeFilesFromReliabilityStorage(submissionAttachmentPaths),
      removeSubmission(submissionID),
    ]);

    console.log(
      JSON.stringify({
        level: "info",
        status: "success",
        submissionId: submissionID,
        sendReceipt: sendReceipt,
        msg: "Successfully saved submission to Vault.",
      })
    );
  } catch (error) {
    // Not throwing an error back to SQS because the message was sucessfully processed by the vault. Only cleanup required.
    console.warn(
      JSON.stringify({
        level: "warn",
        submissionId: submissionID ?? "n/a",
        sendReceipt: sendReceipt ?? "n/a",
        msg: "Successfully saved submission to Vault but failed to clean up submission processing files from database.",
        error: (error as Error).message,
      })
    );
  }
};
