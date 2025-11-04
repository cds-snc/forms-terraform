import { saveToVault, removeSubmission } from "./dataLayer.js";
import { SubmissionAttachmentInformation } from "./file_checksum.js";
import {} from "./file_scanning.js";
import { isFileValid } from "./fileValidation.js";
import {
  copyFilesFromReliabilityToVaultStorage,
  getObjectFirst100BytesInReliabilityBucket,
  removeFilesFromReliabilityStorage,
} from "./s3FileInput.js";
import { FormSubmission } from "./types.js";

export default async (
  submissionID: string,
  sendReceipt: string,
  formSubmission: FormSubmission,
  submissionAttachmentsWithInformation: SubmissionAttachmentInformation[],
  formID: string,
  language: string,
  createdAt: string,
  securityAttribute: string,
  formSubmissionHash: string
) => {
  const submissionAttachmentPaths = submissionAttachmentsWithInformation.map(
    (item) => item.attachmentPath
  );

  try {
    const submissionAttachmentsWithScanStatusesAfterInternalValidation =
      await verifyAndFlagMaliciousSubmissionAttachments(submissionAttachmentsWithInformation);

    const submissionAttachments = buildSubmissionAttachmentJsonRecord(
      submissionAttachmentsWithScanStatusesAfterInternalValidation
    );

    await copyFilesFromReliabilityToVaultStorage(submissionAttachmentPaths);

    await saveToVault(
      submissionID,
      formSubmission.responses,
      submissionAttachments,
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

async function verifyAndFlagMaliciousSubmissionAttachments(
  submissionAttachmentsWithScanStatuses: SubmissionAttachmentInformation[]
): Promise<SubmissionAttachmentInformation[]> {
  return Promise.all(
    submissionAttachmentsWithScanStatuses.map(async (item) => {
      const attachmentFirst100Bytes = await getObjectFirst100BytesInReliabilityBucket(
        item.attachmentPath
      );

      const isFileValidResult = isFileValid(item.attachmentPath, attachmentFirst100Bytes);

      // If we flagged the file as invalid we return the same scan status value AWS Guard Duty offers to avoid breaking Data Retrieval API service integration
      const scanStatus = isFileValidResult ? item.scanStatus : "THREATS_FOUND";

      return {
        ...item,
        scanStatus: scanStatus,
      };
    })
  );
}

function buildSubmissionAttachmentJsonRecord(
  submissionAttachmentsWithScanStatuses: SubmissionAttachmentInformation[]
): string {
  return JSON.stringify(
    submissionAttachmentsWithScanStatuses.map((item) => {
      const attachmentPathParts = item.attachmentPath.split("/");
      const attachmentId = attachmentPathParts.at(-2);
      const attachmentName = attachmentPathParts.at(-1);

      if (attachmentName === undefined || attachmentId === undefined) {
        throw new Error(`Attachment name or ID is undefined. File path: ${item.attachmentPath}.`);
      }

      return {
        id: attachmentId,
        name: attachmentName,
        path: item.attachmentPath,
        scanStatus: item.scanStatus,
        md5: item.md5,
      };
    })
  );
}
