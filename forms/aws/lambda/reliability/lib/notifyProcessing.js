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
  const emailBody = convertMessage(formSubmission);
  const messageSubject = formSubmission.form.emailSubjectEn
    ? formSubmission.form.emailSubjectEn
    : formSubmission.form.titleEn;
  // Need to get this from the submission now.. not the app.
  const submissionFormat = formSubmission.submission;

  const fileInputPaths = extractFileInputResponses(formSubmission);

  // Send to Notify
  if ((submissionFormat !== null) & (submissionFormat.email !== "")) {
    return await retrieveFilesFromReliabilityStorage(fileInputPaths)
      .then(async (files) => {
        try {
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
          const tmpObject = {
            personalisation: {
              subject: messageSubject,
              formResponse: emailBody,
              ...attachFileParameters,
            },
          };

          try {
            console.log(attachFileParameters);
          } catch (err) {
            console.error(err);
          }

          try {
            console.log(`Json stringified object: ${JSON.stringify(attachFileParameters)}`);
          } catch (err) {
            console.error(err);
          }
          try {
            console.log(tmpObject);
          } catch (err) {
            console.error(err);
          }

          try {
            console.log(`Json stringified object: ${JSON.stringify(tmpObject)}`);
          } catch (err) {
            console.error(err);
          }

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
        } catch (err) {
          console.error(err);
          throw new Error("Problem sending to Notify");
        }
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
