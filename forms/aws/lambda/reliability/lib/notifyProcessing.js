// Process request and format for Notify
const { LambdaClient, InvokeCommand } = require("@aws-sdk/client-lambda");
const { NotifyClient } = require("notifications-node-client");
const convertMessage = require("markdown");
const { removeSubmission, formatError, extractFileInputResponses } = require("dataLayer");
const {
  retrieveFilesFromReliabilityStorage,
  removeFilesFromReliabilityStorage,
} = require("s3FileInput");

const REGION = process.env.REGION;

module.exports = async (submissionID, sendReceipt, formSubmission, message) => {
  const templateID = "92096ac6-1cc5-40ae-9052-fffdb8439a90";
  const notify = new NotifyClient("https://api.notification.canada.ca", process.env.NOTIFY_API_KEY);
  // Add form config back to submission to be processed
  formSubmission.form = await getFormTemplate(formSubmission.formID);
  const emailBody = convertMessage(formSubmission);
  const messageSubject = formSubmission.form.emailSubjectEn
    ? formSubmission.form.emailSubjectEn
    : formSubmission.form.titleEn;
  // Need to get this from the submission now.. not the app.
  const submissionFormat = formSubmission.submission;

  const fileInputPaths = extractFileInputResponses(formSubmission);

  // Send to Notify
  if ((submissionFormat !== null) & (submissionFormat.email !== "")) {
    console.log(`File Input Paths: ${fileInputPaths}`);
    return await retrieveFilesFromReliabilityStorage(fileInputPaths)
      .then(async (files) => {
        const attachFileParameters = fileInputPaths.reduce((acc, current, index) => {
          return {
            [`file${index}`]: {
              file: files[index],
              filename: current,
              sending_method: "attach",
            },
            ...acc,
          };
        }, {});

        console.log(`File attachment parameters: ${attachFileParameters}`);
        const tmpObject = {
          personalisation: {
            subject: messageSubject,
            formResponse: emailBody,
            ...attachFileParameters,
          },
        };
        console.log(`Parameters passed to Notify: ${JSON.stringify(tmpObject)}`);

        return await notify
          // Send to static email address and not submission address in form
          .sendEmail(templateID, "forms-formulaires@cds-snc.ca", {
            personalisation: {
              subject: messageSubject,
              formResponse: emailBody,
              ...attachFileParameters,
            },
            reference: submissionID,
          });
      })
      .catch((err) => {
        throw new Error(`Sending to Notify error: ${JSON.stringify(err)}`);
      })
      .then(async () => await removeFilesFromReliabilityStorage(fileInputPaths))
      .then(async () => {
        console.log(
          `{"status": "success", "submissionID": "${submissionID}", "sqsMessage":"${sendReceipt}", "method":"notify"}`
        );
        // Remove data
        return await removeSubmission(message).catch((err) => {
          // Not throwing an error back to SQS because the message was
          // sucessfully processed by Notify.  Only cleanup required.
          console.warn(
            `{"status": "failed", "submissionID": "${submissionID}", "error": "Can not delete entry from reliability db.  Error:${formatError(
              err
            )}", "method":"notify"}`
          );
        });
      });
  } else {
    throw Error("Form can not be submitted due to missing Submission Parameters");
  }
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
