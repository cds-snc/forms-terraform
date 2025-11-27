import { SQSHandler } from 'aws-lambda';
import { sendNotification } from '@lib/email.js';
import { createNotification, getNotification } from '@lib/db.js';

/**
 * Three cases:
 * - Send immediately: pass emails, subject, body (no notificationId)
 * - Queue up to send when process is complete: pass notificationId, emails, subject, body
 * - Queued notification process complete, send it: pass notificationId
 * 
 * @param event 
 * @returns 
 */
export const handler: SQSHandler = async (event) => {
  const records = event.Records;
  try {
    for (const record of records) {
      /**
       * notificationId - optional ID of notification to defer sending until another process has completed
       * emails - array of 1 or more email addresses to send the notification to
       * subject - email subject of the notification
       * body - email body and sent in email as is, formatting should be handled before calling the lambda
       */
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

      // New notification, store for later
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
