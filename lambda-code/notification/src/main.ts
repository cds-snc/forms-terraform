import { Handler, SQSEvent } from 'aws-lambda';
import { sendNotification } from '@lib/email.js';
import { consumeNotification } from '@lib/db.js';

export const handler: Handler = async (event:SQSEvent) => {
  const batch = event.Records.map((message) => {
    const { messageId, body } = message;
    return { messageId, message: JSON.parse(body) };
  });
  
  const results = await Promise.all(batch.map((item) => messageProcessor(item)));

  const batchItemFailures = results
    .filter((result) => !result.status)
    .map((result) => ({ itemIdentifier: result.messageId }));

  // SQS will retry up to 5 times for each failed message
  return { batchItemFailures };
};

const messageProcessor = async ({
  messageId,
  message,
}: {
  messageId: string;
  message: { notificationId: string };
}) => {
  try {
    const { notificationId } = message;
    const notification = await consumeNotification(notificationId);
    if (!notification) {
      throw new Error("Notification not found in database");
    }

    const { Emails: emails, Subject: subject, Body: body } = notification;
    if (!isValidNotification(emails, subject, body)) {
      throw new Error("Skipping notification due to invalid stored data");
    }
    
    await sendNotification(notificationId, emails, subject, body);
    
    return { status: true, messageId };
  } catch (error) {
    console.info(
      JSON.stringify({
        level: "info",
        status: "failed",
        msg: `Failed to process notification id ${message.notificationId ?? "n/a"}`,
        notificationId: message.notificationId ?? "n/a",
        error: (error as Error).message,
      })
    );
    return { status: false, messageId };
  }
}

const isValidNotification = (
  emails: string[] | undefined,
  subject: string | undefined,
  body: string | undefined
): boolean => {
  return Array.isArray(emails) && emails.length > 0 && !!subject && !!body;
}
