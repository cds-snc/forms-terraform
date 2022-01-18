const { NotifyClient } = require("notifications-node-client");
const convertMessage = require("markdown");
const { removeSubmission, formatError, extractFileInputResponses } = require("dataLayer");
const {
  retrieveFilesFromReliabilityStorage,
  removeFilesFromReliabilityStorage,
} = require("s3FileInput");

module.exports = async (submissionID, sendReceipt, formSubmission, language, message) => {
  const templateID = "92096ac6-1cc5-40ae-9052-fffdb8439a90";
  const notify = new NotifyClient("https://api.notification.canada.ca", process.env.NOTIFY_API_KEY);
  const emailBody = convertMessage(formSubmission, language);
  const messageSubject =
    language === "fr"
      ? formSubmission.form.emailSubjectFr
        ? formSubmission.form.emailSubjectFr
        : formSubmission.form.titleFr
      : formSubmission.form.emailSubjectEn
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
                filename: current.split("/").pop(), // Extract file name from storage path
                sending_method: "attach",
              },
              ...acc,
            };
          }, {});

          return await notify
            // Send to static email address and not submission address in form
            .sendEmail(templateID, submissionFormat.email, {
              personalisation: {
                subject: messageSubject,
                formResponse: emailBody,
                ...attachFileParameters,
              },
              reference: submissionID,
            });
        } catch (err) {
          if (err.response) {
            /*
             * The request was made and the server responded with a
             * status code that falls out of the range of 2xx
             */
            const notifyErrors = Array.isArray(err.response.data.errors)
              ? JSON.stringify(err.response.data.errors)
              : err.response.data.errors;
            const errorMessage = `Notify Errored with status code ${err.response.status} and returned the following detailed errors ${notifyErrors}`;
            console.log(errorMessage);
          } else if (err.request) {
            /*
             * The request was made but no response was received, `error.request`
             * is an instance of XMLHttpRequest in the browser and an instance
             * of http.ClientRequest in Node.js
             */
            console.log(err.request);
          } else {
            // Something happened in setting up the request and triggered an Error
            console.log(err.message);
          }
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
