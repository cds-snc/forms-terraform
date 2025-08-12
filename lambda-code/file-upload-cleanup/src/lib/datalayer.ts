import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DeleteCommand, DynamoDBDocument, QueryCommand } from "@aws-sdk/lib-dynamodb";
import { DeleteObjectsCommand, S3Client, HeadObjectCommand } from "@aws-sdk/client-s3";

export enum ReasonBehindUnprocessedSubmission {
  SubmissionIsInReliabilityQueue,
  SubmissionHasAllAttachedFiles,
  SubmissionIsMissingAttachedFiles,
}

type UnprocessedSubmission = {
  submissionId: string;
  fileKeys: string[];
  createdAt: number;
  sendReceipt: string;
};

const S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME = process.env.S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME;

if (!S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME) {
  console.error(
    JSON.stringify({
      level: "warn",
      severity: 3,
      status: "failed",
      msg: "File upload cleanup lambda does not have environment variable for Reliability File Storage S3 bucket name",
    })
  );

  throw new Error("Missing environment variable for S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME");
}

export const awsProperties = {
  region: process.env.REGION ?? "ca-central-1",
};

const SUBMISSION_MAX_AGE_IN_HOURS = 2;

const dynamodb = DynamoDBDocument.from(new DynamoDBClient(awsProperties));

const s3Client = new S3Client(awsProperties);

export async function getUnprocessedSubmissions(lastEvaluatedKey?: Record<string, any>): Promise<{
  unprocessedSubmissions: UnprocessedSubmission[];
  lastEvaluatedKey?: Record<string, any>;
}> {
  return dynamodb
    .send(
      new QueryCommand({
        TableName: "ReliabilityQueue",
        IndexName: "HasFileKeysByCreatedAt",
        Limit: 50,
        ExclusiveStartKey: lastEvaluatedKey,
        ScanIndexForward: true, // Querying from oldest to newest
        KeyConditionExpression: "HasFileKeys = :hasFileKeys AND CreatedAt <= :createdAt",
        FilterExpression: "attribute_not_exists(NotifyProcessed)", // Ignore submissions that will be delivered through GC Notify. They will be automatically deleted after 30 days.
        ExpressionAttributeValues: {
          ":hasFileKeys": 1,
          ":createdAt": Date.now() - SUBMISSION_MAX_AGE_IN_HOURS * 60 * 60 * 1000, // Convert SUBMISSION_MAX_AGE_IN_HOURS to milliseconds
        },
      })
    )
    .then((results) => {
      return {
        unprocessedSubmissions:
          results.Items?.map((item) => ({
            submissionId: item.SubmissionID,
            fileKeys: JSON.parse(item.FileKeys),
            createdAt: item.CreatedAt,
            sendReceipt: item.SendReceipt,
          })) ?? [],
        lastEvaluatedKey: results.LastEvaluatedKey,
      };
    })
    .catch((error) => {
      throw new Error(
        `Failed to retrieve unprocessed submissions. Reason: ${(error as Error).message}.`
      );
    });
}

export async function decideIfUnprocessedSubmissionShouldBeDeleted(
  unprocessedSubmissions: UnprocessedSubmission
): Promise<{ shouldDelete: boolean; reason: ReasonBehindUnprocessedSubmission }> {
  const areAllFilesUploaded = await verifyIfAllFilesExist(unprocessedSubmissions.fileKeys);

  if (areAllFilesUploaded) {
    if (unprocessedSubmissions.sendReceipt !== "unknown") {
      return {
        shouldDelete: false,
        reason: ReasonBehindUnprocessedSubmission.SubmissionIsInReliabilityQueue,
      };
    } else {
      return {
        shouldDelete: false,
        reason: ReasonBehindUnprocessedSubmission.SubmissionHasAllAttachedFiles,
      };
    }
  }

  return {
    shouldDelete: true,
    reason: ReasonBehindUnprocessedSubmission.SubmissionIsMissingAttachedFiles,
  };
}

export async function deleteUnprocessedSubmission(
  unprocessedSubmissions: UnprocessedSubmission
): Promise<void> {
  return deleteFiles(unprocessedSubmissions.fileKeys)
    .then(() => deleteFormResponse(unprocessedSubmissions.submissionId))
    .catch((error) => {
      throw new Error(
        `Failed to delete unprocessed submission ${unprocessedSubmissions.submissionId}. Reason: ${
          (error as Error).message
        }.`
      );
    });
}

const verifyIfAllFilesExist = async (fileKeys: string[]) => {
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

const deleteFiles = async (fileKeys: string[]) => {
  const batchDeleteInput = fileKeys.map((fileKey) => {
    return {
      Key: fileKey,
    };
  });

  const response = await s3Client
    .send(
      new DeleteObjectsCommand({
        Bucket: S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME,
        Delete: {
          Objects: batchDeleteInput,
          Quiet: true,
        },
      })
    )
    .catch((e) => {
      console.error(
        JSON.stringify({
          level: "warn",
          severity: 3,
          status: "failed",
          msg: (e as Error).message,
          details: JSON.stringify(e),
        })
      );
      throw new Error("Failed connecting to Reliability S3 Bucket");
    });

  if (response.Errors) {
    response.Errors.forEach((error) => {
      console.error(
        JSON.stringify({
          level: "warn",
          severity: 3,
          key: error.Key,
          msg: error.Message,
          code: error.Code,
        })
      );
    });
    throw new Error("Could not complete deleting of files from S3 Reliability Storage");
  }
};

const deleteFormResponse = async (submissionId: string) => {
  await dynamodb.send(
    new DeleteCommand({
      TableName: "ReliabilityQueue",
      Key: {
        SubmissionID: submissionId,
      },
    })
  );
};
