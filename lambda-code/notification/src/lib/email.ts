import { GCNotifyConnector } from "@gcforms/connectors";

const gcNotifyConnector = await GCNotifyConnector.defaultUsingApiKeyFromAwsSecret(
  process.env.NOTIFY_API_KEY ?? ""
);

export const sendNotification = async (emails:string[], subject:string, body:string) => {
    // TODO hand case of no emails or other empty content?
  Promise.all(emails.map((emailAddress) => sendEmail(emailAddress, subject, body)));
};

const sendEmail = async (emailAddress: string, subject: string, body: string) => {
  try {
    console.log(`Sending notification to ${emailAddress}`);

    // TODO: Uncomment whenr ready to merge -- will only work on staging and production
    // await gcNotifyConnector.sendEmail(emailAddress, process.env.TEMPLATE_ID ?? "", {
    //     subject: subject,
    //     emailBody: body,
    // });
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
