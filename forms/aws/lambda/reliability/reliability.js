const sendToNotify = require("notifyProcessing");
const sendToVault = require("vaultProcessing");
const sendToMailingList = require("mailingListProcessing");
const { getSubmission, formatError } = require("dataLayer");
const { LambdaClient, InvokeCommand } = require("@aws-sdk/client-lambda");

const REGION = process.env.REGION;

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
          `{"status": "warn", "submissionID": "${submissionID}", "warning": "Submission data does not exist in the DB" }`
        );
      }

      // Add form config back to submission to be processed
      formSubmission.form = await getFormTemplate(formSubmission.formID);

      /// process submission to vault or Notify
      if (formSubmission.submission.vault) {
        console.log("DEBUG >>> calling sendToVault");
        return await sendToVault(submissionID, sendReceipt, formSubmission, formID, message);
      } else if (formSubmission.submission.mailingList) {
        return await sendToMailingList(submissionID, sendReceipt, formSubmission, message);
      } else {
        return await sendToNotify(submissionID, sendReceipt, formSubmission, message);
      }
    })
    .catch((err) => {
      console.error(
        `{"status": "failed", "submissionID": "${submissionIDPlaceholder}", "error": "${formatError(
          err
        )}}"`
      );
      throw new Error("Could not process / Function Error");
    });
};

const getFormTemplate = async (formID) => {
  const lambdaClient = new LambdaClient({ region: REGION });
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
        cosole.error("Lambda Template Client not successful");
        return null;
      } else {
        console.info("Lambda Template Client successfully triggered");

        const response = JSON.parse(payload);
        const { records } = response.data;
        if (records?.length === 1 && records[0].formConfig.form) {
          return {
            formID,
            ...records[0].formConfig.form,
          };
        }
        return null;
      }
    })
    .catch((err) => {
      console.error(err);
      throw new Error("Could not process request with Lambda Templates function");
    });
};
