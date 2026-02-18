import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { GetCommand, DeleteCommand } from "@aws-sdk/lib-dynamodb";

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
      `Failed to retrieve notification id ${notificationId}. Reason: ${(error as Error).message}`
    );
  }
};
