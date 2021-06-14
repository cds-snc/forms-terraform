const { saveToVault, removeSubmission } = require("dataLayer");
module.exports = async (submissionID, sendReceipt, formResponse, formID, message) => {
  return await saveToVault(submissionID, formResponse, formID)
    .catch((err) => {
      throw new Error(`Saving to Vault error: ${JSON.stringify(err)}`);
    })
    .then(async () => {
      console.log(
        `Sucessfully processed SQS message ${sendReceipt} for Submission ${submissionID}`
      );
      // Remove data
      return await removeSubmission(message).catch((err) => {
        // Not throwing an error back to SQS because the message was
        // sucessfully processed by the vault.  Only cleanup required.
        throw new Error(
          `Could not delete submission ${submissionID} from DB.  Error: ${
            typeof err === "object" ? JSON.stringify(err) : err
          }`
        );
      });
    })
    .then(() => {
      console.log("Saved to the Vault");
    });
};
