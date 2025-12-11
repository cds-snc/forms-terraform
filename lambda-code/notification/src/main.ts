import { Handler, SQSEvent } from 'aws-lambda';
import { sendNotification } from '@lib/email.js';
import { consumeNotification } from '@lib/db.js';

export const handler: Handler = async (event:SQSEvent) => {
  const batch = event.Records.map((message) => {
    const { messageId, body } = message;
    return { messageId, body };
  });
  
  const results = await Promise.all(batch.map((item) => messageProcessor(item)));

  const batchItemFailures = results
    .filter((result) => !result.status)
    .map((result) => ({ itemIdentifier: result.messageId }));

  return { batchItemFailures };
};

const messageProcessor = async ({
  messageId,
  body,
}: {
  messageId: string;
  body: string;
}) => {
  try {
    const { notificationId }: { notificationId: string } = JSON.parse(body);
    const notification = await consumeNotification(notificationId);
    if (!notification) {
      throw new Error(`Not found in database id ${notificationId}`);
    }

    const { Emails: emails, Subject: subject, Body: emailBody } = notification;
    if (!isValidNotification(emails, subject, emailBody)) {
      throw new Error(`Skipping due to invalid stored data id ${notificationId}`);
    }
    
    await sendNotification(notificationId, emails, subject, emailBody);
    
    return { status: true, messageId };
  } catch (error) {
    console.info(
      JSON.stringify({
        level: "info",
        status: "failed",
        msg: `Failed to process notification`,
        error: (error as Error).message,
      })
    );
    // Will retry up to 5 times and report an error on batch failure
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
