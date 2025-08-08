import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { UpdateCommand, GetCommand, DynamoDBDocumentClient } from "@aws-sdk/lib-dynamodb";
import { SQSClient, SendMessageCommand } from "@aws-sdk/client-sqs";
import { S3Client, HeadObjectCommand } from "@aws-sdk/client-s3";

export type Submission = {
  sendReceipt: string;
  fileKeys?: string[];
};

const S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME = process.env.S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME;

if (!S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME) {
  console.error(
    JSON.stringify({
      level: "warn",
      severity: 3,
      status: "failed",
      msg: "File upload processor lambda does not have environment variable for Reliability File Storage S3 bucket name",
    })
  );

  throw new Error("Missing environment variable for S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME");
}

const awsProperties = {
  region: process.env.REGION ?? "ca-central-1",
};

const dynamodb = DynamoDBDocumentClient.from(new DynamoDBClient(awsProperties));

const sqs = new SQSClient(awsProperties);

const s3Client = new S3Client(awsProperties);

export const extractSubmissionIdFromObjectKey = (objectKey: string) => {
  // key = form_attachements/05-05-2025/submissionId/fileRefId/filename
  return decodeURIComponent(objectKey.replace(/\+/g, " ")).split("/", 4)[2];
};

export const retrieveSubmission = async (submissionId: string): Promise<Submission> => {
  return dynamodb
    .send(
      new GetCommand({
        TableName: "ReliabilityQueue",
        Key: {
          SubmissionID: submissionId,
        },
        ProjectionExpression: "FileKeys,SendReceipt",
      })
    )
    .then((result) => {
      if (result.Item === undefined) {
        throw new Error(`Failed to retrieve submission ${submissionId}`);
      }

      return {
        sendReceipt: result.Item.SendReceipt,
        ...(result.Item.FileKeys && { fileKeys: JSON.parse(result.Item.FileKeys) }),
      } as Submission;
    });
};

export const verifyIfAllFilesExist = async (fileKeys: string[]) => {
  const s3Promises = fileKeys.map(async (fileKey) =>
    s3Client
      .send(
        new HeadObjectCommand({
          Bucket: S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME,
          Key: fileKey,
        })
      )
      .then(() => {
        return true;
      })
      .catch((err) => {
        if (err && err.name === "NotFound") {
          return false;
        }
        console.error(err);
        throw err;
      })
  );
  const results = await Promise.all(s3Promises);
  return results.reduce((prev, curr) => prev && curr, true);
};

export const enqueueReliabilityProcessingRequest = async (
  submissionId: string
): Promise<string> => {
  try {
    const sendMessageCommandOutput = await sqs.send(
      new SendMessageCommand({
        MessageBody: JSON.stringify({
          submissionID: submissionId,
        }),
        // Helps ensure the file scanning job is processed first
        DelaySeconds: 5,
        QueueUrl: process.env.SQS_URL,
      })
    );

    if (!sendMessageCommandOutput.MessageId) {
      throw new Error("Received null SQS message identifier");
    }

    return sendMessageCommandOutput.MessageId;
  } catch (error) {
    throw new Error("Could not enqueue reliability processing request. " + JSON.stringify(error));
  }
};

export const updateReceiptIdForSubmission = async (
  submissionId: string,
  receiptId: string
): Promise<void> => {
  try {
    await dynamodb.send(
      new UpdateCommand({
        TableName: "ReliabilityQueue",
        Key: {
          SubmissionID: submissionId,
        },
        UpdateExpression: "SET SendReceipt = :receiptId",
        ExpressionAttributeValues: {
          ":receiptId": receiptId,
        },
      })
    );
  } catch (error) {
    console.warn(
      JSON.stringify({
        level: "warn",
        submissionId: submissionId,
        msg: `Could not update submission in reliability queue table with receipt identifier`,
        error: (error as Error).message,
      })
    );
  }
};
