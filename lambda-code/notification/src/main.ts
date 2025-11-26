import { SQSHandler } from 'aws-lambda';
import AWS from 'aws-sdk';

const dynamoDB = new AWS.DynamoDB.DocumentClient();
const notifyAPI = new AWS.SNS(); // Replace with Notify API client

const NOTIFICATION_TABLE = process.env.DYNAMODB_TABLE || '';
const NOTIFICATION_QUEUE = process.env.NOTIFICATION_QUEUE || '';

export const handler: SQSHandler = async (event) => {
  for (const record of event.Records) {
    try {
      const message = JSON.parse(record.body);
      const { correlationId, content } = message;

      if (!correlationId) {
        // Case 1: No correlationId, send immediately
        await sendNotification(content);
      } else {
        // Check if a record exists for the correlationId
        const existingRecord = await getRecord(correlationId);

        if (!existingRecord) {
          // Case 2: No existing record, create a new one
          await createRecord(correlationId, content);
        } else {
          // Case 3: Existing record, format and send notification
          const formattedContent = formatContent(existingRecord, content);
          await sendNotification(formattedContent);
        }
      }
    } catch (error) {
      console.error('Error processing message:', error);
    }
  }
};

const sendNotification = async (content: any) => {
  console.log('Sending notification:', content);
  // Replace with Notify API call
};

const getRecord = async (correlationId: string) => {
  const params = {
    TableName: NOTIFICATION_TABLE,
    Key: { correlationId },
  };

  const result = await dynamoDB.get(params).promise();
  return result.Item;
};

const createRecord = async (correlationId: string, content: any) => {
  const params = {
    TableName: NOTIFICATION_TABLE,
    Item: { correlationId, content },
  };

  await dynamoDB.put(params).promise();
};

const formatContent = (existingRecord: any, newContent: any) => {
  // add formatting 
  return { ...existingRecord, ...newContent };
};