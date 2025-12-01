import { SQSHandler } from 'aws-lambda';
import { sendNotification } from '@lib/email.js';
import { createNotification, getNotification } from '@lib/db.js';

// TODO:
// - add sqs notification event to reliablity queue (if no existing notificationId will be ignored) -- ok I think?
// - add notification to file production-lambda-functions.config.json
// - should notification be added to aws/lambdas/cloudwatch.tf?
// - should notification be added to aws/alarms/cloudwatch_app.tf?

/**
 * SQS Lambda handler for sending email notifications.
 * 
 * Three cases:
 * 1. Send immediately: pass emails, subject, body (no notificationId)
 * 2. Queue up to send when process is complete: pass notificationId, emails, subject, body
 * 3. Queued notification process complete, send it: pass only notificationId
 *
 * @param event - SQS event containing notification messages
 * @param event.Records[].body - JSON string with the following structure:
 * @param event.Records[].body.notificationId - (optional) Id to defer sending until another process completes
 * @param event.Records[].body.emails - Array of email addresses to send the notification to
 * @param event.Records[].body.subject - Email subject line
 * @param event.Records[].body.body - Email body content (should be pre-formatted for email delivery)
 */
export const handler: SQSHandler = async (event) => {
  const records = event.Records;
  try {
    for (const record of records) {
      const {notificationId, emails, subject, body} = JSON.parse(record.body);

      // TEMP
      console.log(`Processing notification: notificationId=${notificationId}, emails=${JSON.stringify(emails)}, subject=${subject}, body=${body}`);
      
      // Case 1: send notification immediately
      if (!notificationId) {
        if (!validNotification(emails, subject, body)) {
          console.warn(
              JSON.stringify({
                level: "warn",
                emails: emails,
                subject: subject,
                body: subject,
                msg: "notification handler will skip sending this notification because it received invalid parameters.",
              })
            );
          return;
        }

        await sendNotification(emails, subject, body);
        return;
      } 

      const notification = await getNotification(notificationId);

      // Case 2: New notification, create and store for later
      if (!notification) {
        if (!validNotification(emails, subject, body)) {
          console.warn(
              JSON.stringify({
                level: "warn",
                emails: emails,
                subject: subject,
                body: subject,
                msg: "notification handler failed because it received invalid parameters.",
              })
            );
          return;
        }

        await createNotification(notificationId, emails, subject, body); 
        return;
      } 

      // Case 3: Existing notification, process completed, send it
      await sendNotification(notification.Emails, notification.Subject, notification.Body);
    }
  } catch (error) {
    console.error('Error processing notification:', error);
  }
};

const validNotification = (emails: string[] | undefined, subject: string | undefined, body: string | undefined) => {
  return Array.isArray(emails) && emails.length > 0 && subject && body;
}
