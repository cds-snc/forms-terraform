import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { PutCommand, GetCommand } from "@aws-sdk/lib-dynamodb";

const NOTIFICATION_TABLE = process.env.DYNAMODB_NOTIFICATION_TABLE_NAME ?? "";

const dynamodbClient = new DynamoDBClient({
  region: process.env.REGION ?? "ca-central-1",
});

export const getDeferredNotification = async (notificationId: string) => {
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

    console.log(
      JSON.stringify({
        level: "info",
        msg: `Successfully retrieved deferred notification ${notificationId}`,
      })
    );

    return result.Item;
  } catch (error) {
    throw new Error(
      `Failed to check for notification with id ${notificationId}. Reason: ${(error as Error).message}`
    );
  }
};

export const createDeferredNotification = async (notificationId:string, emails:string[], subject:string, body:string) => {
  try {
    await dynamodbClient.send(
      new PutCommand({
        TableName: NOTIFICATION_TABLE,
        Item: {
          NotificationID: notificationId,
          Emails: emails,
          Subject: subject,
          Body: body,
        },
      })
    );

    console.log(
      JSON.stringify({
        level: "info",
        msg: `Successfully created deferred notification ${notificationId}`,
      })
    );
  } catch (error) {
    throw new Error(
      `Failed to create notification ${notificationId}. Reason: ${(error as Error).message}`
    );
  }
};
