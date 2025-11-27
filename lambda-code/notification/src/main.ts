import { SQSHandler } from 'aws-lambda';
import { sendNotification } from '@lib/email.js';
import { createNotification, getNotification } from '@lib/db.js';

export const handler: SQSHandler = async (event) => {
  const records = event.Records;
  try {
    for (const record of records) {
      const {notificationId, emails, subject, body} = JSON.parse(record.body);
      
      // TEMP
      console.log(`Processing notification: notificationId=${notificationId}, emails=${JSON.stringify(emails)}, subject=${subject}, body=${body}`);

      // Case 1: send message immediately
      if (!notificationId) {
        await sendNotification(emails, subject, body);
        return;
      } 

      // Case 2: defer message and send after another proces has finished
      const notification = await getNotification(notificationId);

      // New message, store for later
      if (!notification) {
        console.log("NOTIFICATION CASE 2 - creating new notification record");

        await createNotification(notificationId, emails, subject, body);
        return;
      } 

      // Existing message, process completed, send it
      await sendNotification(emails, subject, body);
    }
  } catch (error) {
    console.error('Error processing message:', error);
  }
};
