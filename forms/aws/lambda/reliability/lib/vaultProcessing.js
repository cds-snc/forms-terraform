const { saveToVault, removeSubmission, formatError, extractFileInputResponses } = require("dataLayer");
const { copyFilesFromReliabilityToVaultStorage, removeFilesFromReliabilityStorage } = require("s3FileInput");

module.exports = async (submissionID, sendReceipt, formSubmission, formID, message) => {
  const fileInputPaths = extractFileInputResponses(formSubmission);
  return await copyFilesFromReliabilityToVaultStorage(fileInputPaths)
    .then(async () => await removeFilesFromReliabilityStorage(fileInputPaths))
    .then(async () => await saveToVault(submissionID, formSubmission.responses, formID))
    .catch((err) => { throw new Error(`Saving to Vault error: ${formatErr(err)}`) })
    .then(async () => {
      console.log(
        `{"status": "success", "submissionID": "${submissionID}", "sqsMessage":"${sendReceipt}", "method":"vault"}`
      );
      // Remove data
      return await removeSubmission(message).catch((err) => {
        // Not throwing an error back to SQS because the message was
        // sucessfully processed by the vault.  Only cleanup required.
        console.warn(
          `{"status": "failed", "submissionID": "${submissionID}", "error": "Can not delete entry from reliability db.  Error:${formatError(
            err
          )}", "method":"vault" }`
        );
      });
    });
};
