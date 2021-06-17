const sendToNotify = require("notifyProcessing");
const sendToVault = require("vaultProcessing");
const { getSubmission } = require("dataLayer");

exports.handler = async function (event) {
  let submissionIDPlaceholder = "";

  const message = JSON.parse(event.Records[0].body);
  return await getSubmission(message)
    .then((messageData) => ({
      submissionID: messageData.Item?.SubmissionID.S ?? message.submissionID,
      formID: messageData.Item?.FormID.S ?? null,
      sendReceipt: messageData.Item?.SendReceipt.S ?? null,
      formSubmission: messageData.Item?.FormData.S
        ? JSON.parse(messageData.Item?.FormData.S)
        : null,
    }))
    .then(async ({ submissionID, sendReceipt, formSubmission, formID }) => {
      submissionIDPlaceholder = submissionID;
      // Check if form data exists or was already processed.
      if (formSubmission === null || typeof formSubmission === "undefined") {
        // Ack and remove message from queue if it doesn't exist in the DB
        // Do not throw an error so it does not retry again
        console.warn(
          `No corresponding submission for Submission ID: ${submissionID} in the reliability database`
        );
        console.warn("Data no longer exists in the DB");
      }
      /// process submission to vault or Notify

      if (formSubmission.submission.vault) {
        return await sendToVault(
          submissionID,
          sendReceipt,
          formSubmission.responses,
          formID,
          message
        );
      } else {
        return await sendToNotify(submissionID, sendReceipt, formSubmission, message);
      }
    })
    .catch((err) => {
      console.error(err);
      console.error(`Error in processing, submission ${submissionIDPlaceholder} not processed.`);
      throw new Error("Could not process / Function Error");
    });
};
