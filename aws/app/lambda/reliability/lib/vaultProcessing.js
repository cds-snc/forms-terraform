const { saveToVault, extractFileInputResponses } = require("dataLayer");
const { copyFilesFromReliabilityToVaultStorage } = require("s3FileInput");

module.exports = async (submissionID, sendReceipt, formSubmission, formID, language, createdAt) => {
  const fileInputPaths = extractFileInputResponses(formSubmission);
  return await copyFilesFromReliabilityToVaultStorage(fileInputPaths)
    .then(async () => await saveToVault(submissionID, formSubmission.responses, formID, language, createdAt))
    .catch((err) => {
      throw new Error(`Saving to Vault error: ${formatErr(err)}`);
    })
    .then(async () => {
      console.log(
        `{"status": "success", "submissionID": "${submissionID}", "sqsMessage":"${sendReceipt}", "method":"vault"}`
      );
      return Promise.resolve();
    });
};
