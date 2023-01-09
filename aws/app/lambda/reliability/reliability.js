const sendToNotify = require("notifyProcessing");
const sendToVault = require("vaultProcessing");
const { getTemplateFormConfig } = require("templates");
const { getSubmission } = require("dataLayer");

exports.handler = async function (event) {
  const message = JSON.parse(event.Records[0].body);

  try {
    const messageData = await getSubmission(message);
    const submissionID = messageData.Item?.SubmissionID.S ?? message.submissionID;
    const formID = messageData.Item?.FormID.S ?? null;
    const formSubmission = messageData.Item?.FormData.S ? JSON.parse(messageData.Item?.FormData.S) : null;
    const language = messageData.Item?.FormSubmissionLanguage.S ?? "en";
    const securityAttribute = messageData.Item?.SecurityAttribute.S ?? "Unclassified";
    const createdAt = messageData.Item?.CreatedAt.N ?? null;
    const sendReceipt = messageData.Item?.SendReceipt.S ?? null;

    // Check if form data exists or was already processed.
    if (formSubmission === null || typeof formSubmission === "undefined") {
      // Ack and remove message from queue if it doesn't exist in the DB
      // Do not throw an error so it does not retry again
      console.warn(JSON.stringify({
        status: "success",
        submissionId: submissionID,
        sendReceipt: sendReceipt,
        message: "Submission will not be processed because it could not be found in the database.",
      }));
      return { status: true };
    }

    // Add form config back to submission to be processed
    formSubmission.form = await getTemplateFormConfig(formID);

    if (formSubmission.form === null) {
      throw new Error(`No associated form template (ID: ${formID}) exist in the database.`);
    }

    /*
     Process submission to vault or Notify
     Form submission object contains:
       formID - ID of form,
       language - form submission language "fr" or "en",
       submission - submission type: email, vault
       responses - form responses: {formID, securityAttribute, questionID: answer}
       form - Complete Form Template
    */

    if (formSubmission.submission.vault) {
      return await sendToVault(
        submissionID,
        sendReceipt,
        formSubmission,
        formID,
        language,
        createdAt,
        securityAttribute
      );
    } else {
      return await sendToNotify(submissionID, sendReceipt, formSubmission, language, createdAt);
    }
  } catch (error) {
    console.error(JSON.stringify({
      status: "failed",
      submissionId: message.submissionID,
      sendReceipt: sendReceipt,
      message: "Failed to process submission.",
      error: `${error.message}`,
    }));
    throw new Error(`Failed to process submission.`);
  }
};
