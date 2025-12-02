import { Handler, SQSEvent, SQSHandler } from 'aws-lambda';
import { sendNotification } from '@lib/email.js';
import { createDeferredNotification, consumeDeferredNotification } from '@lib/db.js';

interface DeferredNotification {
  NotificationID: string;
  Emails: string[];
  Subject: string;
  Body: string;
}

// TODO:
// - Reminder to add notification to file production-lambda-functions.config.json before merging to staging

/**
 * SQS Lambda handler for sending email notifications.
 * 
 * The notificationId is used as a flag to determine the type of processing:
 * If the notificationId is not provided, send immediately.
 * If the notificationId is provided but not found in DB, create deferred notification.
 * If the notificationId is provided and found in DB, send the completed notification.
 */
export const handler: Handler = async (event:SQSEvent) => {
  for (const record of event.Records) {
    try {
      const { notificationId, emails, subject, body } = JSON.parse(record.body);  // Add type

      // SQS cannot handle large messages, create record on app db connector side
      // e.g. coat checking with ticket, so create ticket first, then process here

      if (!notificationId) {
        await handleImmediateNotification(emails, subject, body);
        return;
      }

      const notification = await consumeDeferredNotification(notificationId);

      if (!notification) {
        await handleCreateDeferredNotification(notificationId, emails, subject, body);
        return;
      }

      await handleCompletedDeferredNotification(
        notification.NotificationID,
        notification.Emails,
        notification.Subject,
        notification.Body
      );
    } catch (error) {
      console.error(
        JSON.stringify({
          level: "error",
          msg: "Failed to process notification record",
          messageId: record.messageId,
          error: (error as Error).message,
        })
      );
      // Continue processing other records even if one fails
    }
  }
};

async function handleImmediateNotification(
  emails: string[],
  subject: string,
  body: string
): Promise<void> {
  if (!isValidNotification(emails, subject, body)) {
    console.warn(
      JSON.stringify({
        level: "warn",
        msg: "Skipping immediate notification due to invalid parameters",
        hasEmails: !!emails,
        hasSubject: !!subject,
        hasBody: !!body,
      })
    );
    return;
  }

  await sendNotification(emails, subject, body);
}

async function handleCreateDeferredNotification(
  notificationId: string,
  emails: string[],
  subject: string,
  body: string
): Promise<void> {
  if (!isValidNotification(emails, subject, body)) {
    console.warn(
      JSON.stringify({
        level: "warn",
        msg: "Failed to defer notification due to invalid parameters",
        notificationId,
        hasEmails: !!emails,
        hasSubject: !!subject,
        hasBody: !!body,
      })
    );
    return;
  }

  await createDeferredNotification(notificationId, emails, subject, body);
}

async function handleCompletedDeferredNotification(
  notificationId: string,
  emails: string[],
  subject: string,
  body: string
): Promise<void> {
  if (!isValidNotification(emails, subject, body)) {
    console.warn(
      JSON.stringify({
        level: "warn",
        msg: "Skipping completed notification due to invalid stored data",
        notificationId: notificationId,
      })
    );
    return;
  }

  await sendNotification(emails, subject, body);
}

function isValidNotification(
  emails: string[] | undefined,
  subject: string | undefined,
  body: string | undefined
): boolean {
  return Array.isArray(emails) && emails.length > 0 && !!subject && !!body;
}
