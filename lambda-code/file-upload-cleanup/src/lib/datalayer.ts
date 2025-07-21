import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  ScanCommandOutput,
  DeleteCommand,
  ScanCommand,
  DynamoDBDocument,
} from "@aws-sdk/lib-dynamodb";
import {
  DeleteObjectsCommand,
  S3Client,
  HeadObjectCommand,
  DeleteObjectCommand,
} from "@aws-sdk/client-s3";

export const awsProperties = {
  region: process.env.REGION ?? "ca-central-1",
};

const cleanupMaxAge = 60 * 60 * 2; // 2 hours

const dynamodb = DynamoDBDocument.from(new DynamoDBClient(awsProperties));

const s3Client = new S3Client(awsProperties);

const reliabilityFileStorage = process.env.RELIABILITY_FILE_STORAGE;
if (!reliabilityFileStorage) {
  console.error(
    JSON.stringify({
      level: "warn",
      severity: 3,
      status: "failed",
      msg: "File Cleanup Lambda does not have environment variable for Reliability File Storage",
    })
  );
}

type CleanupRecord = {
  submissionId: string;
  fileKeys: string[];
  createdAt: number;
  sendReceipt: string;
  notifyProcessed?: boolean;
};

export const getSubmissionsToVerify = async (): Promise<CleanupRecord[]> => {
  let lastEvaluatedKey: Record<string, any> | undefined = undefined;
  let operationComplete = false;
  const recordsToVerify: CleanupRecord[] = [];

  while (!operationComplete) {
    const result: ScanCommandOutput = await dynamodb.send(
      new ScanCommand({
        TableName: "ReliabilityQueue",
        IndexName: "FileKeysCreatedAt",
        FilterExpression: `CreatedAt <= :createdAt`,
        ExpressionAttributeValues: {
          ":createdAt": Date.now() - cleanupMaxAge, // 2419200000 milliseconds = 28 days
        },
        ...(lastEvaluatedKey && { ExclusiveStartKey: lastEvaluatedKey }),
      })
    );

    if (result.Items) {
      recordsToVerify.push(
        ...result.Items.map((item) => ({
          submissionId: item.SubmissionID,
          fileKeys: JSON.parse(item.FileKeys),
          createdAt: item.CreatedAt,
          sendReceipt: item.SendReceipt,
          notifyProcessed: item.NotifyProcessed,
        }))
      );
    }

    if (result.LastEvaluatedKey) {
      lastEvaluatedKey = result.LastEvaluatedKey;
    } else {
      operationComplete = true;
    }
  }

  return recordsToVerify;
};

export const cleanupFailedUploads = async (items: CleanupRecord[]) => {
  return Promise.allSettled(
    items.map(async (item) => {
      const { submissionId, fileKeys, createdAt, sendReceipt, notifyProcessed } = item;

      // Do not cleanup files with email delivery.  They will automatically delete after 30 days.
      if (notifyProcessed !== undefined) {
        return;
      }

      const areAllFilesUploaded = await verifyIfAllFilesExist(fileKeys);

      if (areAllFilesUploaded) {
        if (sendReceipt !== "unknown") {
          console.error(
            JSON.stringify({
              level: "error",
              severity: 2,
              submissionId: submissionId,
              msg: "Possible issue with Reliability Queue processing",
              details: `Submission ${submissionId} has been sent into the Reliabilty Queue but has not been processed in over ${Math.floor(
                (Date.now() - createdAt) / 3600
              )} hours`,
            })
          );
          return;
        } else {
          console.error(
            JSON.stringify({
              level: "error",
              severity: 2,
              submissionId: submissionId,
              msg: "Possible issue with File Upload processing",
              details: `Submission ${submissionId} has been successfully uploaded but not processed by the File Processing lambda in over ${Math.floor(
                (Date.now() - createdAt) / 3600
              )} hours`,
            })
          );
          return;
        }
      }

      // Remove partially uploaded file responses
      await deleteFiles(fileKeys);
      // Ensure files are removed before removing form submission from reliability storage
      await deleteFormResponse(submissionId);

      console.info(
        `Deleted partially completed submission ID ${submissionId} and associated Files`
      );
    })
  );
};

const verifyIfAllFilesExist = async (fileKeys: string[]) => {
  const s3Promises = fileKeys.map(async (fileKey) =>
    s3Client
      .send(
        new HeadObjectCommand({
          Bucket: reliabilityFileStorage,
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
        Bucket: reliabilityFileStorage,
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
