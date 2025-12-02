import { GCNotifyConnector } from "@gcforms/connectors";

const gcNotifyConnector = await GCNotifyConnector.defaultUsingApiKeyFromAwsSecret(
  process.env.NOTIFY_API_KEY ?? ""
);

export const sendNotification = async (emails:string[], subject:string, body:string) => {
  await Promise.all(emails.map((emailAddress) => sendEmail(emailAddress, subject, body)));
  
  console.log(
    JSON.stringify({
      level: "info",
      msg: "Notification sent successfully",
      emailCount: emails.length,
    })
  );
};

// TODO: Probably don't need template_id?
// TODO: Anything to configure on Notify side? 
const sendEmail = async (emailAddress: string, subject: string, body: string) => {
  try {
    // TODO uncomment before merging to staging
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
