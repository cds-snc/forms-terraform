import { Handler, SQSEvent } from 'aws-lambda';
import { sendNotification } from '@lib/email.js';
import { consumeNotification } from '@lib/db.js';

// TODO: Reminder to add notification to file production-lambda-functions.config.json before merging to staging

interface NotificationSQSMessage {
  notificationId: string;
}

// SQS Lambda handler for sending email notifications
export const handler: Handler = async (event:SQSEvent) => {
  for (const record of event.Records) {
    try {
      const { notificationId } = JSON.parse(record.body) as NotificationSQSMessage;

      const notification = await consumeNotification(notificationId);
      if (!notification) {
        console.warn(
          JSON.stringify({
            level: "warn",
            msg: "Notification not found in database",
            notificationId,
            sqsMessageId: record.messageId,
          })
        );
        continue;
      }

      const { Emails: emails, Subject: subject, Body: body } = notification;
      if (!isValidNotification(emails, subject, body)) {
        console.warn(
          JSON.stringify({
            level: "warn",
            msg: "Skipping notification due to invalid stored data",
            notificationId,
            sqsMessageId: record.messageId,
            hasEmails: Array.isArray(emails) && emails.length > 0,
            hasSubject: !!subject,
            hasBody: !!body,
          })
        );
        continue;
      }

      await sendNotification(notificationId, emails, subject, body);
    } catch (error) {
      console.error(
        JSON.stringify({
          level: "error",
          msg: "Failed to process notification record",
          sqsMessageId: record.messageId,
          error: (error as Error).message,
        })
      );
      // Continue processing other records even if one fails
    }
  }
};

function isValidNotification(
  emails: string[] | undefined,
  subject: string | undefined,
  body: string | undefined
): boolean {
  return Array.isArray(emails) && emails.length > 0 && !!subject && !!body;
}
