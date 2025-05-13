import { saveToVault, extractFileInputResponses, removeSubmission } from "./dataLayer.js";

import {
  copyFilesFromReliabilityToVaultStorage,
  removeFilesFromReliabilityStorage,
} from "./s3FileInput.js";
import { FormSubmission } from "./types.js";

export default async (
  submissionID: string,
  sendReceipt: string,
  formSubmission: FormSubmission,
  formID: string,
  language: string,
  createdAt: string,
  securityAttribute: string,
  formSubmissionHash: string
) => {
  let fileInputPaths = [];

  try {
    fileInputPaths = extractFileInputResponses(formSubmission);
    await copyFilesFromReliabilityToVaultStorage(fileInputPaths);
    await saveToVault(
      submissionID,
      formSubmission.responses,
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
      removeFilesFromReliabilityStorage(fileInputPaths),
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
