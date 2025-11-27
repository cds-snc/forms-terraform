import { SQSHandler } from 'aws-lambda';
import { sendNotification } from '@lib/email.js';
import { createNotification, getNotification } from '@lib/db.js';

/**
 * SQS Lambda handler for sending email notifications.
 * 
 * Three cases:
 * - Send immediately: pass emails, subject, body (no notificationId)
 * - Queue up to send when process is complete: pass notificationId, emails, subject, body
 * - Queued notification process complete, send it: pass notificationId
 *
 * @param event - SQS event containing notification messages
 * @param event.Records[].body - JSON string with the following structure:
 * @param event.Records[].body.notificationId - (optional) ID to defer sending until another process completes
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
        await sendNotification(emails, subject, body);
        return;
      } 

      // Case 2: defer notification and send after another proces has finished
      const notification = await getNotification(notificationId);

      // New notification, create and store for later
      if (!notification) {
        await createNotification(notificationId, emails, subject, body);
        return;
      } 

      // Existing notification, process completed, send it
      await sendNotification(notification.Emails, notification.Subject, notification.Body);
    }
  } catch (error) {
    console.error('Error processing notification:', error);
  }
};
