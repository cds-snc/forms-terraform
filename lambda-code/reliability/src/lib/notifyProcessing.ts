import { EmailAttachment, GCNotifyConnector } from "@gcforms/connectors";
import convertMessage from "./markdown.ts";
import { notifyProcessed } from "./dataLayer.ts";
import { retrieveFilesFromReliabilityStorage } from "./s3FileInput.ts";
import { FormSubmission } from "./types.ts";
import { SubmissionAttachmentInformation } from "./file_checksum.ts";

const gcNotifyConnector =
  await GCNotifyConnector.defaultUsingApiKeyFromAwsSecret(
    process.env.NOTIFY_API_KEY ?? "",
  );

export default async (
  submissionID: string,
  sendReceipt: string,
  formSubmission: FormSubmission,
  submissionAttachmentsWithInformation: SubmissionAttachmentInformation[],
  language: string,
  createdAt: string,
) => {
  try {
    // Making sure currently processed submission email address is defined
    if (
      !formSubmission.deliveryOption?.emailAddress ||
      formSubmission.deliveryOption.emailAddress === ""
    ) {
      throw Error("Email address is missing or empty.");
    }

    const submissionAttachmentPaths = submissionAttachmentsWithInformation.map(
      (item) => item.attachmentPath,
    );

    const submissionAttachments = submissionAttachmentsWithInformation.map(
      (item) => {
        const attachmentName = item.attachmentPath.split("/").pop();

        if (attachmentName === undefined) {
          throw new Error(
            `Attachment name is undefined. File path: ${item.attachmentPath}.`,
          );
        }

        return {
          name: attachmentName,
          path: item.attachmentPath,
        };
      },
    );

    const files = await retrieveFilesFromReliabilityStorage(
      submissionAttachmentPaths,
    );

    const emailAttachments: EmailAttachment[] = submissionAttachments.map(
      (attachment, index) => {
        return { fileName: attachment.name, base64EncodedFile: files[index] };
      },
    );

    const templateId = process.env.TEMPLATE_ID;

    if (templateId === undefined) {
      throw new Error(
        `Missing Environment Variables: ${templateId ? "" : "Template ID"}`,
      );
    }

    const emailBody = convertMessage(
      formSubmission,
      submissionID,
      language,
      createdAt,
    );
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
      {
        templateId,
        placeholders: {
          subject: messageSubject,
          formResponse: emailBody,
        },
        attachments: emailAttachments,
      },
      submissionID,
    );

    await notifyProcessed(submissionID);

    console.log(
      JSON.stringify({
        level: "info",
        status: "success",
        submissionId: submissionID,
        sendReceipt: sendReceipt,
        msg: "Successfully sent submission through GC Notify.",
      }),
    );
  } catch (error) {
    console.error(
      JSON.stringify({
        level: "error",
        severity: "2",
        submissionId: submissionID ?? "n/a",
        sendReceipt: sendReceipt ?? "n/a",
        msg: "Failed to send submission through GC Notify",
        error: (error as Error).message,
      }),
    );

    throw new Error(`Failed to send submission through GC Notify.`);
  }
};
