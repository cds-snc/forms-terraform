import { Handler, SQSEvent } from "aws-lambda";
import sendToNotify from "./lib/notifyProcessing.js";
import sendToVault from "./lib/vaultProcessing.js";
import { getTemplateFormConfig } from "./lib/templates.js";
import { getSubmission } from "./lib/dataLayer.js";

export const handler: Handler = async (event: SQSEvent) => {
  const message = JSON.parse(event.Records[0].body);

  let sendReceipt = null;

  try {
    const messageData = await getSubmission(message);
    const submissionID = messageData.Item?.SubmissionID ?? message.submissionID;
    const formID =
      // dynamodb client could possibl return as a number due to early form identifiers being numeric
      typeof messageData.Item?.FormID === "string"
        ? messageData.Item?.FormID
        : messageData.Item?.FormID.toString() ?? null;
    const formSubmission = messageData.Item?.FormData
      ? JSON.parse(messageData.Item?.FormData)
      : null;
    const language = messageData.Item?.FormSubmissionLanguage ?? "en";
    const securityAttribute = messageData.Item?.SecurityAttribute ?? "Protected A";
    const createdAt = messageData.Item?.CreatedAt ?? null;
    const notifyProcessed = messageData.Item?.NotifyProcessed ?? false;
    sendReceipt = messageData.Item?.SendReceipt ?? null;
    const formSubmissionHash = messageData.Item?.FormSubmissionHash ?? null;

    // Check if form data exists or was already processed.
    if (formSubmission === null || notifyProcessed) {
      // Ack and remove message from queue if it doesn't exist in the DB
      // Do not throw an error so it does not retry again
      console.warn(
        JSON.stringify({
          level: "warn",
          status: "success",
          submissionId: submissionID,
          sendReceipt: sendReceipt,
          msg: "Submission will not be processed because it could not be found in the database or has already been processed.",
        })
      );
      return { status: true };
    }

    const configs = await getTemplateFormConfig(formID);

    if (configs !== null && configs.formConfig !== null) {
      // Add form config back to submission to be processed
      formSubmission.form = configs.formConfig;
      // add delivery option to formsubmission
      formSubmission.deliveryOption = configs.deliveryOption;
    } else {
      console.error(
        JSON.stringify({
          level: "error",
          severity: 2,
          msg: `No associated form template (ID: ${formID}) exist in the database.`,
        })
      );
      throw new Error(`No associated form template (ID: ${formID}) exist in the database.`);
    }

    /*
     Process submission to vault or Notify
     Form submission object contains:
       formID - ID of form,
       language - form submission language "fr" or "en",
       responses - form responses: {formID, securityAttribute, questionID: answer}
       form - Complete Form Template
       deliveryOption - (optional) Will be present if user wants to receive form responses by email (`{ emailAddress: string; emailSubjectEn?: string; emailSubjectFr?: string }`)
    */

    if (formSubmission.deliveryOption) {
      return await sendToNotify(submissionID, sendReceipt, formSubmission, language, createdAt);
    } else {
      return await sendToVault(
        submissionID,
        sendReceipt,
        formSubmission,
        formID,
        language,
        createdAt,
        securityAttribute,
        formSubmissionHash
      );
    }
  } catch (error) {
    console.warn(
      JSON.stringify({
        level: "warn",
        severity: 2,
        status: "failed",
        submissionId: message.submissionID ?? "n/a",
        sendReceipt: sendReceipt ?? "n/a",
        msg: `Failed to process submission ID ${message.submissionID ?? "n/a"}`,
        error: (error as Error).message,
      })
    );

    // Log full error to console, it will not be sent to Slack
    console.warn(JSON.stringify(error));

    throw new Error(JSON.stringify({ status: "failed" }));
  }
};
