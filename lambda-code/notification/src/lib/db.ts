import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { PutCommand, GetCommand, DeleteCommand } from "@aws-sdk/lib-dynamodb";

const NOTIFICATION_TABLE = process.env.DYNAMODB_NOTIFICATION_TABLE_NAME ?? "";
const REGION = process.env.REGION ?? "ca-central-1";

const dynamodbClient = new DynamoDBClient({
  region: REGION,
});

interface Notification {
  NotificationID: string;
  Emails: string[];
  Subject: string;
  Body: string;
}

export const consumeNotification = async (
  notificationId: string
): Promise<Notification | undefined> => {
  try {
    const result = await dynamodbClient.send(
      new GetCommand({
        TableName: NOTIFICATION_TABLE,
        Key: {
          NotificationID: notificationId,
        },
      })
    );

    if (!result.Item) {
      return undefined;
    }

    await dynamodbClient.send(
      new DeleteCommand({
        TableName: NOTIFICATION_TABLE,
        Key: {
          NotificationID: notificationId,
        },
      })
    );

    return result.Item as Notification;
  } catch (error) {
    throw new Error(
      `Failed to retrieve notification ${notificationId}. Reason: ${(error as Error).message}`
    );
  }
};

// export const createNotification = async (
//   notificationId: string,
//   emails: string[],
//   subject: string,
//   body: string
// ): Promise<void> => {
//   try {
//     const ttl = Math.floor(Date.now() / 1000) + 86400; // 24 hours from now
//     await dynamodbClient.send(
//       new PutCommand({
//         TableName: NOTIFICATION_TABLE,
//         Item: {
//           NotificationID: notificationId,
//           Emails: emails,
//           Subject: subject,
//           Body: body,
//           TTL: ttl,
//         },
//       })
//     );

//     console.log(
//       JSON.stringify({
//         level: "info",
//         msg: `Successfully created deferred notification ${notificationId}`,
//       })
//     );
//   } catch (error) {
//     throw new Error(
//       `Failed to create notification ${notificationId}. Reason: ${(error as Error).message}`
//     );
//   }
// };
