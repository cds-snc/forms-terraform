const sendToNotify = require("notifyProcessing");
const { getSubmission } = require("dataLayer");

exports.handler = async function (event) {
  let submissionIDPlaceholder = "";

  const message = JSON.parse(event.Records[0].body);
  return await getSubmission(message)
    .then((messageData) => ({
      submissionID: messageData.Item.SubmissionID.S || null,
      sendReceipt: messageData.Item.SendReceipt.S || null,
      formSubmission: JSON.parse(messageData.Item.FormData.S) || null,
    }))
    .then(({ submissionID, sendReceipt, formSubmission }) => {
      submissionIDPlaceholder = submissionID;
      // Check if form data exists or was already processed.
      if (formSubmission === null || typeof formSubmission === "undefined") {
        // Ack and remove message from queue if it doesn't exist in the DB
        console.warn(
          `No corresponding submission for Submission ID: ${submissionID} in the reliability database`
        );
        return { statusCode: 202, body: "Data no longer exists in DB" };
      }
      /// process submission to vault or Notify

      if (formSubmission.vault) {
        // Send to vault
      } else {
        return sendToNotify(submissionID, sendReceipt, formSubmission, message);
      }
    })
    .catch((err) => {
      console.error(err);
      console.error(`Error in processing, submission ${submissionIDPlaceholder} not processed.`);
      return { statusCode: 500, body: "Could not process / Function Error" };
    });
};
