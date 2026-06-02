import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { GetCommand } from "@aws-sdk/lib-dynamodb";
import { Notification } from "@lib/types.js";

const dynamodbClient = new DynamoDBClient({
  region: process.env.REGION ?? "ca-central-1",
});

export const retrieveNotification = async (
  notificationId: string
): Promise<Notification | undefined> => {
  try {
    const result = await dynamodbClient.send(
      new GetCommand({
        TableName: process.env.DYNAMODB_NOTIFICATION_TABLE_NAME ?? "",
        Key: {
          NotificationID: notificationId,
        },
      })
    );

    if (result.Item === undefined) {
      return undefined;
    }

    return {
      id: result.Item.NotificationID,
      emailRecipients: result.Item.Emails,
      emailSubject: result.Item.Subject,
      emailBody: result.Item.Body,
    };
  } catch (error) {
    throw new Error(
      `Failed to retrieve notification ${notificationId}. Reason: ${(error as Error).message}`
    );
  }
};
