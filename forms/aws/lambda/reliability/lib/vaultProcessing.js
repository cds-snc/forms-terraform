const { saveToVault, removeSubmission } = require("dataLayer");
module.exports = async (submissionID, sendReceipt, formSubmission, message) => {
  saveToVault(submissionID, formSubmission)
    .catch((err) => {
      console.error(`Saving to Vault error: ${JSON.stringify(err)}`);
      return { statusCode: 500, body: "Could not process / Function Error" };
    })
    .then(async () => {
      console.log(
        `Sucessfully processed SQS message ${sendReceipt} for Submission ${submissionID}`
      );
      // Remove data
      await removeSubmission(message).catch((err) => {
        // Not throwing an error back to SQS because the message was
        // sucessfully processed by Notify.  Only cleanup required.
        console.error(
          `Could not delete submission ${submissionID} from DB.  Error: ${
            typeof err === "object" ? JSON.stringify(err) : err
          }`
        );
      });
    })
    .then(() => ({ statusCode: 202, body: "Stored in the Vault" }));
};
