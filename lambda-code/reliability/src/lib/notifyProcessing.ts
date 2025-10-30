import { GCNotifyConnector } from "@gcforms/connectors";
import convertMessage from "./markdown.js";
import { notifyProcessed } from "./dataLayer.js";
import { retrieveFilesFromReliabilityStorage } from "./s3FileInput.js";
import { FormSubmission } from "./types.js";
import { SubmissionAttachmentWithScanStatus } from "./file_scanning.js";

const gcNotifyConnector = await GCNotifyConnector.defaultUsingApiKeyFromAwsSecret(
  process.env.NOTIFY_API_KEY ?? ""
);

export default async (
  submissionID: string,
  sendReceipt: string,
  formSubmission: FormSubmission,
  submissionAttachmentsWithScanStatuses: SubmissionAttachmentWithScanStatus[],
  language: string,
  createdAt: string
) => {
  try {
    // Making sure currently processed submission email address is defined
    if (
      !formSubmission.deliveryOption?.emailAddress ||
      formSubmission.deliveryOption.emailAddress === ""
    ) {
      throw Error("Email address is missing or empty.");
    }

    const submissionAttachmentPaths = submissionAttachmentsWithScanStatuses.map(
      (item) => item.attachmentPath
    );

    const submissionAttachments = submissionAttachmentsWithScanStatuses.map((item) => {
      const attachmentName = item.attachmentPath.split("/").pop();

      if (attachmentName === undefined) {
        throw new Error(`Attachment name is undefined. File path: ${item.attachmentPath}.`);
      }

      return {
        name: attachmentName,
        path: item.attachmentPath,
      };
    });

    const files = await retrieveFilesFromReliabilityStorage(submissionAttachmentPaths);

    const attachFileParameters = submissionAttachments.reduce((acc, current, index) => {
      return {
        [`file${index}`]: {
          file: files[index],
          filename: current.name,
          sending_method: "attach",
        },
        ...acc,
      };
    }, {});

    const templateId = process.env.TEMPLATE_ID;

    if (templateId === undefined) {
      throw new Error(`Missing Environment Variables: ${templateId ? "" : "Template ID"}`);
    }

    const emailBody = convertMessage(formSubmission, submissionID, language, createdAt);
    const messageSubject =
      language === "fr"
        ? formSubmission.deliveryOption.emailSubjectFr
          ? formSubmission.deliveryOption.emailSubjectFr
          : formSubmission.form.titleFr
        : formSubmission.deliveryOption.emailSubjectEn
        ? formSubmission.deliveryOption.emailSubjectEn
        : formSubmission.form.titleEn;

    await gcNotifyConnector.sendEmail(
      formSubmission.deliveryOption.emailAddress,
      templateId,
      {
        subject: messageSubject,
        formResponse: emailBody,
        ...attachFileParameters,
      },
      submissionID
    );

    await notifyProcessed(submissionID);

    console.log(
      JSON.stringify({
        level: "info",
        status: "success",
        submissionId: submissionID,
        sendReceipt: sendReceipt,
        msg: "Successfully sent submission through GC Notify.",
      })
    );
  } catch (error) {
    console.error(
      JSON.stringify({
        level: "error",
        severity: 2,
        submissionId: submissionID ?? "n/a",
        sendReceipt: sendReceipt ?? "n/a",
        msg: "Failed to send submission through GC Notify",
        error: (error as Error).message,
      })
    );

    throw new Error(`Failed to send submission through GC Notify.`);
  }
};
