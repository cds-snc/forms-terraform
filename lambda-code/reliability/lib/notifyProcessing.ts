import { GCNotifyClient } from "./gc-notify-client.js";
import convertMessage from "./markdown.js";
import { extractFileInputResponses, notifyProcessed } from "./dataLayer.js";
import { retrieveFilesFromReliabilityStorage } from "./s3FileInput.js";
import { FormSubmission } from "./types.js";
import { AxiosError } from "axios";
import { SecretsManagerClient, GetSecretValueCommand } from "@aws-sdk/client-secrets-manager";

const client = new SecretsManagerClient();
const command = new GetSecretValueCommand({ SecretId: process.env.NOTIFY_API_KEY });
console.log("Retrieving Notify API Key from Secrets Manager");
const notifyApiKey = await client.send(command);

if (notifyApiKey.SecretString === undefined) {
  throw new Error("GCNotify API key is undefined");
}

const gcNotifyClient = GCNotifyClient.default(notifyApiKey.SecretString);

export default async (
  submissionID: string,
  sendReceipt: string,
  formSubmission: FormSubmission,
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

    const fileInputPaths = extractFileInputResponses(formSubmission);
    const files = await retrieveFilesFromReliabilityStorage(fileInputPaths);
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

    await gcNotifyClient.sendEmail(
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
