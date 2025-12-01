import { GCNotifyConnector } from "@gcforms/connectors";

const gcNotifyConnector = await GCNotifyConnector.defaultUsingApiKeyFromAwsSecret(
  process.env.NOTIFY_API_KEY ?? ""
);

export const sendNotification = async (emails:string[], subject:string, body:string) => {
  if (!Array.isArray(emails) || emails.length === 0) {
    console.warn("No email addresses provided, skipping notification.");
    return;
  }

  Promise.all(emails.map((emailAddress) => sendEmail(emailAddress, subject, body)));
};

// TODO: Probably don't need template_id?
// TODO: Anything to configure on Notify side? 
const sendEmail = async (emailAddress: string, subject: string, body: string) => {
  try {
    await gcNotifyConnector.sendEmail(emailAddress, process.env.TEMPLATE_ID ?? "", {
        subject: subject,
        emailBody: body,
    });
    console.log(`Sent notification to ${emailAddress}`);
  } catch (error) {
    // Error Message will be sent to slack -- Will this be too verbose for slack?
    console.error(
        JSON.stringify({
            level: "error",
            msg: `Failed to send notification to: ${emailAddress}.`,
            error: (error as Error).message,
        })
    );

    // Continue to send notifications even if one fails
    return;
  }
}
