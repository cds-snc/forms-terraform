const { NotifyClient } = require("notifications-node-client");
const convertMessage = require("markdown");
const { extractFileInputResponses, updateTTL } = require("dataLayer");
const { retrieveFilesFromReliabilityStorage } = require("s3FileInput");

module.exports = async (submissionID, sendReceipt, formSubmission, language, createdAt) => {
  try {
    // Making sure currently processed submission email address is defined
    if (!formSubmission.submission?.email || formSubmission.submission.email === "") {
      throw Error("Email address is missing or empty.");
    }

    const fileInputPaths = extractFileInputResponses(formSubmission);
    const files = await retrieveFilesFromReliabilityStorage(fileInputPaths)
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

    const templateID = process.env.TEMPLATE_ID;
    const notify = new NotifyClient("https://api.notification.canada.ca", process.env.NOTIFY_API_KEY);
    const emailBody = convertMessage(formSubmission, submissionID, language, createdAt);
    const messageSubject =
      language === "fr"
        ? formSubmission.form.emailSubjectFr
          ? formSubmission.form.emailSubjectFr
          : formSubmission.form.titleFr
        : formSubmission.form.emailSubjectEn
        ? formSubmission.form.emailSubjectEn
        : formSubmission.form.titleEn;

    await notify
      .sendEmail(templateID, formSubmission.submission.email, {
        personalisation: {
          subject: messageSubject,
          formResponse: emailBody,
          ...attachFileParameters,
        },
        reference: submissionID,
      });

    await updateTTL(submissionID);

    console.log(JSON.stringify({
      status: "success",
      submissionId: submissionID,
      sendReceipt: sendReceipt,
      message: "Successfully sent submission through GC Notify.",
    }));
  } catch (error) {
    let errorMessage = "";

    if (error.response) {
      /*
       * The request was made and the server responded with a
       * status code that falls out of the range of 2xx
       */
      const notifyErrors = Array.isArray(error.response.data.errors)
        ? JSON.stringify(error.response.data.errors)
        : error.response.data.errors;
      errorMessage = `GC Notify errored with status code ${error.response.status} and returned the following detailed errors ${notifyErrors}.`;
    } else if (error.request) {
      /*
       * The request was made but no response was received, `error.request`
       * is an instance of XMLHttpRequest in the browser and an instance
       * of http.ClientRequest in Node.js
       */
      errorMessage = `${error.request}.`;
    } else {
      // Something else happened during processing
      errorMessage = `${error.message}.`;
    }

    console.error(JSON.stringify({
      status: "failed",
      submissionId: submissionID,
      sendReceipt: sendReceipt,
      message: "Failed to send submission through GC Notify.",
      error: errorMessage,
    }));
    throw new Error(`Failed to send submission through GC Notify.`);
  }
};
