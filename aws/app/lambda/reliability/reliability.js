const sendToNotify = require("notifyProcessing");
const sendToVault = require("vaultProcessing");
const { getTemplateFormConfig } = require("templates");
const { getSubmission, formatError } = require("dataLayer");
const { LambdaClient, InvokeCommand } = require("@aws-sdk/client-lambda");

const REGION = process.env.REGION;

exports.handler = async function (event) {
  let submissionIDPlaceholder = "";

  const message = JSON.parse(event.Records[0].body);
  try {
    const messageData = await getSubmission(message);
    const processedMessageData = {
      submissionID: messageData.Item?.SubmissionID.S ?? message.submissionID,
      formID: messageData.Item?.FormID.S ?? null,
      sendReceipt: messageData.Item?.SendReceipt.S ?? null,
      language: messageData.Item?.FormSubmissionLanguage.S ?? "en",
      createdAt: messageData.Item?.CreatedAt.N ?? null,
      formSubmission: messageData.Item?.FormData.S
        ? JSON.parse(messageData.Item?.FormData.S)
        : null,
      securityAttribute: messageData.Item?.SecurityAttribute.S ?? "Unclassified",
    };

    const {
      submissionID,
      formSubmission,
      formID,
      sendReceipt,
      createdAt,
      language,
      securityAttribute,
    } = processedMessageData;
    submissionIDPlaceholder = submissionID;
    // Check if form data exists or was already processed.
    if (formSubmission === null || typeof formSubmission === "undefined") {
      // Ack and remove message from queue if it doesn't exist in the DB
      // Do not throw an error so it does not retry again

      console.warn(
        `{"status": "warn", "submissionID": "${submissionID}", "warning": "Submission data does not exist in the DB" }`
      );
    }

    // Add form config back to submission to be processed
    formSubmission.form = await getTemplateFormConfig(formSubmission.formID);
    if (formSubmission.form === null) {
      throw new Error(`No Form with ID ${formSubmission.formID} found to process response`);
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
  } catch (err) {
    console.error(
      `{"status": "failed", "submissionID": "${submissionIDPlaceholder}", "error": "${formatError(
        err
      )}}"`
    );
    throw new Error("Could not process / Function Error");
  }
};
