const { saveToVault, removeSubmission, formatError } = require("dataLayer");

module.exports = async (submissionID, sendReceipt, formResponse, formID, message) => {
  return await saveToVault(submissionID, formResponse, formID)
    .catch((err) => {
      throw new Error(`Saving to Vault error: ${formatErr(err)}`);
    })
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
