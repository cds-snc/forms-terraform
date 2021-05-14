// Process request and format for Notify
const { NotifyClient } = require("notifications-node-client");
const convertMessage = require("markdown");
const { removeSubmission } = require("dataLayer");

async function sendToNotify(formSubmission, sendReceipt) {
  const templateID = "92096ac6-1cc5-40ae-9052-fffdb8439a90";
  const notify = new NotifyClient("https://api.notification.canada.ca", process.env.NOTIFY_API_KEY);
  const emailBody = convertMessage(formSubmission);
  const messageSubject = `${
    formSubmission.form.emailSubjectEn
      ? formSubmission.form.emailSubjectEn
      : formSubmission.form.titleEn
  } Submission`;
  // Need to get this from the submission now.. not the app.
  const submissionFormat = formSubmission.submission;
  // Send to Notify

  if ((submissionFormat !== null) & (submissionFormat.email !== "")) {
    return await notify
      // Send to static email address and not submission address in form
      .sendEmail(templateID, "forms-formulaires@cds-snc.ca", {
        personalisation: {
          subject: messageSubject,
          formResponse: emailBody,
        },
        reference: submissionID,
      })
      .catch((err) => {
        console.error(`Sending to Notify error: ${JSON.stringify(err)}`);
        return { statusCode: 500, body: "Could not process / Function Error" };
      })
      .then(async () => {
        console.log(
          `Sucessfully processed SQS message ${sendReceipt} for Submission ${submissionID}`
        );
        // Remove data
        await removeSubmission(message).catch((err) => {
          // Not throwing an error back to SQS because the message was
          // sucessfully processed by Notify.  Only cleanup required.
          console.error(
            `Could not delete submission ${submissionID} from DB.  Error: ${
              typeof err === "object" ? JSON.stringify(err) : err
            }`
          );
        });
      })
      .then(() => ({ statusCode: 202, body: "Received by Notify" }));
  } else {
    throw Error("Form can not be submitted due to missing Submission Parameters");
  }
}

module.exports -
  {
    sendToNotify,
  };
