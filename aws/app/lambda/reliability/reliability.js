const sendToNotify = require("notifyProcessing");
const sendToVault = require("vaultProcessing");
const { getSubmission, formatError } = require("dataLayer");
const { LambdaClient, InvokeCommand } = require("@aws-sdk/client-lambda");

const REGION = process.env.REGION;

exports.handler = async function (event) {
  let submissionIDPlaceholder = "";

  const message = JSON.parse(event.Records[0].body);
  try{

    const messageData = await getSubmission(message)
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
    }

    const {submissionID, formSubmission, formID, sendReceipt, createdAt, language} = processedMessageData
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
    formSubmission.form = await getFormTemplate(formSubmission.formID);

    /// process submission to vault or Notify
    if (formSubmission.submission.vault) {
      return await sendToVault(submissionID, sendReceipt, formSubmission, formID, language, createdAt);
    } else {
      return await sendToNotify(submissionID, sendReceipt, formSubmission, language, createdAt);
    }
  } catch(err) {
    console.error(
      `{"status": "failed", "submissionID": "${submissionIDPlaceholder}", "error": "${formatError(
        err
      )}}"`
    );
    throw new Error("Could not process / Function Error");
  }
};

const getFormTemplate = async (formID) => {
  const lambdaClient = new LambdaClient({ region: REGION, endpoint: process.env.AWS_SAM_LOCAL ? "http://host.docker.internal:3001": undefined });
  const encoder = new TextEncoder();

  const command = new InvokeCommand({
    FunctionName: "Templates",
    Payload: encoder.encode(
      JSON.stringify({
        method: "GET",
        formID,
      })
    ),
  });
  return await lambdaClient
    .send(command)
    .then((response) => {
      const decoder = new TextDecoder();
      const payload = decoder.decode(response.Payload);
      if (response.FunctionError) {
        console.error("Lambda Template Client not successful");
        return null;
      } else {
        console.info("Lambda Template Client successfully triggered");

        const response = JSON.parse(payload);
        const { records } = response.data;
        if (records?.length === 1 && records[0].formConfig.form) {
          const formTemplate = {formID,
            ...records[0].formConfig.form,
            securityAttribute: records[0].formConfig.securityAttribute ?? "Unclassified"
          }           
          return formTemplate;
        }
        return null;
      }
    })
    .catch((err) => {
      console.error(err);
      throw new Error("Could not process request with Lambda Templates function");
    });
};
