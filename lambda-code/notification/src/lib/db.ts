import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { PutCommand, GetCommand } from "@aws-sdk/lib-dynamodb";

const NOTIFICATION_TABLE = process.env.DYNAMODB_NOTIFICATION_TABLE_NAME ?? "";

const dynamodbClient = new DynamoDBClient({
  region: process.env.REGION ?? "ca-central-1",
});

export const getNotification = async (notificationId: string) => {
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
      console.log(
        JSON.stringify({
          level: "warn",
          msg: `Notification ${notificationId} not found`,
        })
      );
      return undefined;
    }

    return result.Item;
  } catch (error) {
    throw new Error(
      `Failed to retrieve notification ${notificationId}. Reason: ${(error as Error).message}`
    );
  }
};

export const createNotification = async (notificationId:string, emails:string[], subject:string, body:string) => {
  try {
    // const timeStamp = Date.now();
    await dynamodbClient.send(
      new PutCommand({
        TableName: NOTIFICATION_TABLE,
        Item: {
          NotificationID: notificationId,
          Emails: emails,
          Subject: subject,
          Body: body,
        //   Status: "Pending",
        //   CreatedAt: timeStamp,
        //   UpdatedAt: timeStamp,
        },
      })
    );

    console.log(
      JSON.stringify({
        level: "info",
        msg: `Successfully created notification ${notificationId}`,
      })
    );
  } catch (error) {
    throw new Error(
      `Failed to create notification ${notificationId}. Reason: ${(error as Error).message}`
    );
  }
};
