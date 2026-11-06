import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { S3Client } from "@aws-sdk/client-s3";
import { SQSClient } from "@aws-sdk/client-sqs";
import { DynamoDBDocument } from "@aws-sdk/lib-dynamodb";

const region = process.env.REGION ?? "ca-central-1";

export const dynamodbClient = DynamoDBDocument.from(new DynamoDBClient({ region }));

export const s3Client = new S3Client({ region });

export const sqsClient = new SQSClient({ region });
