import { SQSClient, SendMessageCommand } from "@aws-sdk/client-sqs";

//
// TODO replace with call from imported @gcforms package
//

const sqs = new SQSClient({
  region: process.env.REGION ?? "ca-central-1",
});

const NOTIFICATION_QUEUE_URL = process.env.NOTIFICATION_QUEUE_URL ?? "";

export const enqueueDeferredNotificationMessage = async (notificationId: string): Promise<void> => {
  try {
    const sendMessageCommandOutput = await sqs.send(
      new SendMessageCommand({
        MessageBody: JSON.stringify({
          notificationId,
        }),
        QueueUrl: NOTIFICATION_QUEUE_URL,

      })
    );

    if (!sendMessageCommandOutput.MessageId) {
      throw new Error("Received null SQS message identifier");
    }

    console.log(
      JSON.stringify({
        level: "info",
        msg: `Successfully queued deferred notification`,
        notificationId
      })
    );
  } catch (error) {
    console.log(
      JSON.stringify({
        level: "info",
        msg: `Could not enqueue deferred notification`,
        notificationId,
        error: JSON.stringify(error),
      })
    );
  }
};
