import { S3EventRecord } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { UpdateCommand, GetCommand } from "@aws-sdk/lib-dynamodb";
import { SQSClient, SendMessageCommand } from "@aws-sdk/client-sqs";
import { S3Client, HeadObjectCommand } from "@aws-sdk/client-s3";

const awsProperties = {
  region: process.env.REGION ?? "ca-central-1",
};

const dynamodb = new DynamoDBClient(awsProperties);

const sqs = new SQSClient(awsProperties);

const s3Client = new S3Client(awsProperties);

export const retrieveSubmissionId = (event: S3EventRecord) => {
  // key = form_attachements/05-05-2025/submissionId/fileRefId/filename

  const submissionId = decodeURIComponent(event.s3.object.key.replace(/\+/g, " ")).split("/", 4)[2];
  const bucketName = event.s3.bucket.name;
  return { submissionId, bucketName };
};

export const getFileKeysForSubmission = async (submissionId: string): Promise<string[]> => {
  const result = await dynamodb.send(
    new GetCommand({
      TableName: "ReliabilityQueue",
      Key: {
        SubmissionID: submissionId,
      },
      ProjectionExpression: "FileKeys",
    })
  );
  return JSON.parse(result.Item?.FileKeys) ?? [];
};

export const verifyIfAllFilesExist = async (fileKeys: string[], bucket: string) => {
  const s3Promises = fileKeys.map(async (fileKey) =>
    s3Client
      .send(
        new HeadObjectCommand({
          Bucket: bucket,
          Key: fileKey,
        })
      )
      .then((result) => {
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
  console.info(
    results.map((result, index) => `file key: ${fileKeys[index]} / uploaded: ${result}`).join("\n")
  );
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
