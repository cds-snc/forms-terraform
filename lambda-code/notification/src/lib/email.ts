import { GCNotifyConnector } from "@gcforms/connectors";
import { Notification } from "@lib/types.js";

const gcNotifyConnector = await GCNotifyConnector.defaultUsingApiKeyFromAwsSecret(
  process.env.NOTIFY_API_KEY ?? ""
);

export const notifyByEmail = async (notification: Notification): Promise<void> => {
  const operations = notification.emailRecipients.map((emailAddress) => {
    return sendEmail(emailAddress, notification.emailSubject, notification.emailBody);
  });

  const operationResults = await Promise.allSettled(operations);

  const failedOperations = operationResults.filter((r) => r.status === "rejected");

  if (failedOperations.length === notification.emailRecipients.length) {
    throw new Error("Failed to send notification to all recipients");
  }
};

const sendEmail = async (emailAddress: string, subject: string, body: string): Promise<void> => {
  return gcNotifyConnector
    .sendEmail(emailAddress, process.env.TEMPLATE_ID ?? "", {
      subject: subject,
      formResponse: body,
    })
    .catch((error) => {
      const errorMessage = (error as Error).message;

      if (errorMessage.includes("Request timed out")) {
        console.warn(
          JSON.stringify({
            level: "warn",
            msg: `Request to send email to ${emailAddress} timed out`,
            error: (error as Error).message,
          })
        );

        // We believe the GC Notify API is timing out while processing our request but still sending the email successfully. Therefore, we will treat this error as a successful delivery
        return;
      } else {
        console.error(
          JSON.stringify({
            level: "error",
            msg: `Failed to send email to ${emailAddress}`,
            error: (error as Error).message,
          })
        );

        throw error;
      }
    });
};
