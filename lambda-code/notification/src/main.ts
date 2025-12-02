import { SQSHandler } from 'aws-lambda';
import { sendNotification } from '@lib/email.js';
import { createDeferredNotification, getDeferredNotification } from '@lib/db.js';

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
 */
export const handler: SQSHandler = async (event) => {
  for (const record of event.Records) {
    try {
      const { notificationId, emails, subject, body } = JSON.parse(record.body);

      if (!notificationId) {
        await handleImmediateNotification(emails, subject, body);
        return;
      }

      const notification = await getDeferredNotification(notificationId);

      if (!notification) {
        await handleCreateDeferredNotification(notificationId, emails, subject, body);
        return;
      }

      await handleCompletedNotification(notification.NotificationID, notification.Emails, notification.Subject, notification.Body);
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

async function handleCompletedNotification(
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
