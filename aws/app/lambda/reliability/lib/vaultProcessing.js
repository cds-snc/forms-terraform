const { saveToVault, extractFileInputResponses, removeSubmission } = require("dataLayer");

const {
  copyFilesFromReliabilityToVaultStorage,
  removeFilesFromReliabilityStorage,
} = require("s3FileInput");

module.exports = async (
  submissionID,
  sendReceipt,
  formSubmission,
  formID,
  language,
  createdAt,
  securityAttribute
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
      securityAttribute
    );
  } catch (error) {
    console.error(
      JSON.stringify({
        status: "failed",
        submissionId: submissionID,
        sendReceipt: sendReceipt,
        message: "Failed to save submission to Vault.",
        error: `${error.message}`,
      })
    );
    throw new Error(`Failed to save submission to Vault.`);
  }

  try {
    await Promise.all([
      removeFilesFromReliabilityStorage(fileInputPaths),
      removeSubmission(submissionID),
    ]);

    console.warn(
      JSON.stringify({
        status: "success",
        submissionId: submissionID,
        sendReceipt: sendReceipt,
        message: "Successfully saved submission to Vault.",
      })
    );
  } catch (error) {
    // Not throwing an error back to SQS because the message was sucessfully processed by the vault. Only cleanup required.
    console.warn(
      JSON.stringify({
        status: "success",
        submissionId: submissionID ?? "n/a",
        sendReceipt: sendReceipt ?? "n/a",
        message:
          "Successfully saved submission to Vault but failed to clean up submission processing files from database.",
        error: `${error.message}`,
      })
    );
  }
};
