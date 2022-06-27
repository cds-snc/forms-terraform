const {
  saveToVault,
  extractFileInputResponses,
  removeSubmission,
  formatErr,
} = require("dataLayer");
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
  let fileInputPaths
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
  } catch (err) {
    throw new Error(`Saving to Vault error: ${formatErr(err)}`);
  }

  try {
    await Promise.all([
      removeFilesFromReliabilityStorage(fileInputPaths),
      removeSubmission(submissionID),
    ]);
  } catch (err) {
    // Not throwing an error back to SQS because the message was
    // sucessfully processed by the vault.  Only cleanup required.
    console.warn(
      `{"status": "failed", "submissionID": "${submissionID}", "error": "Can not delete entry from reliability db.  Error:${formatError(
        err
      )}", "method":"vault" }`
    );
  }

  console.log(
    `{"status": "success", "submissionID": "${submissionID}", "sqsMessage":"${sendReceipt}", "method":"vault"}`
  );
};
