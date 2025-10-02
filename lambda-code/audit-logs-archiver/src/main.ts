import { Context, Handler } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { BatchWriteCommand, QueryCommand } from "@aws-sdk/lib-dynamodb";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";

const REGION = process.env.REGION;
const AUDIT_LOGS_DYNAMODB_TABLE_NAME = process.env.AUDIT_LOGS_DYNAMODB_TABLE_NAME;
const AUDIT_LOGS_ARCHIVE_STORAGE_S3_BUCKET = process.env.AUDIT_LOGS_ARCHIVE_STORAGE_S3_BUCKET;
const PROCESSING_CHUNK_SIZE = 100;

interface AuditLog {
  UserID: string;
  TimeStamp: number;
  "Event#SubjectID#TimeStamp": string;
  [key: string]: any;
}

const dynamodbClient = new DynamoDBClient({
  region: REGION ?? "ca-central-1",
});

const s3Client = new S3Client({
  region: REGION ?? "ca-central-1",
});

export const handler: Handler = async (_, context) => {
  try {
    await archiveAuditLogs(dynamodbClient, s3Client, context);
  } catch (error) {
    // Error message will be sent to slack
    console.error(
      JSON.stringify({
        level: "error",
        msg: "Failed to run Audit Logs Archiver",
        error: (error as Error).message,
      })
    );

    throw new Error((error as Error).message);
  }
};

async function archiveAuditLogs(
  dynamodbClient: DynamoDBClient,
  s3Client: S3Client,
  lambdaContext: Context
): Promise<void> {
  let lastEvaluatedKey = null;

  // Exit loop if no more items to process or lambda will time out in less than a minute
  while (lastEvaluatedKey !== undefined && lambdaContext.getRemainingTimeInMillis() >= 60000) {
    const archivableAuditLogs = await retrieveArchivableAuditLogs(
      dynamodbClient,
      lastEvaluatedKey ?? undefined
    );

    if (archivableAuditLogs.auditLogs.length > 0) {
      const auditLogsToDelete = await putAuditLogsInS3(s3Client, archivableAuditLogs.auditLogs);
      await deleteAuditLogsFromDynamoDB(dynamodbClient, auditLogsToDelete);
    }

    lastEvaluatedKey = archivableAuditLogs.lastEvaluatedKey;
  }
}

async function retrieveArchivableAuditLogs(
  dynamodbClient: DynamoDBClient,
  lastEvaluatedKey?: Record<string, any>
): Promise<{ auditLogs: AuditLog[]; lastEvaluatedKey?: Record<string, any> }> {
  const archiveDate = ((d) => d.setMonth(d.getMonth() - 1))(new Date()); // Archive after 1 month

  try {
    const queryCommandResponse = await dynamodbClient.send(
      new QueryCommand({
        TableName: AUDIT_LOGS_DYNAMODB_TABLE_NAME,
        IndexName: "StatusByTimestamp",
        Limit: PROCESSING_CHUNK_SIZE,
        ExclusiveStartKey: lastEvaluatedKey,
        ScanIndexForward: true, // Querying audit logs from oldest to newest
        KeyConditionExpression: "#status = :status AND #timestamp < :timestamp",
        ExpressionAttributeNames: {
          "#status": "Status",
          "#timestamp": "TimeStamp",
        },
        ExpressionAttributeValues: {
          ":status": "Archivable",
          ":timestamp": archiveDate,
        },
      })
    );

    return {
      auditLogs: (queryCommandResponse.Items ?? []) as AuditLog[],
      lastEvaluatedKey: queryCommandResponse.LastEvaluatedKey,
    };
  } catch (error) {
    throw new Error(
      `Failed to retrieve archivable audit logs. Reason: ${(error as Error).message}.`
    );
  }
}

async function putAuditLogsInS3(s3Client: S3Client, auditLogs: AuditLog[]): Promise<AuditLog[]> {
  const putRequests = auditLogs.map(async (auditLog) => {
    try {
      await s3Client.send(
        new PutObjectCommand({
          Bucket: AUDIT_LOGS_ARCHIVE_STORAGE_S3_BUCKET,
          Body: JSON.stringify(auditLog),
          Key: `${auditLog.UserID}/${new Date(auditLog.TimeStamp).toISOString().slice(0, 10)}/${
            auditLog["Event#SubjectID#TimeStamp"]
          }.json`,
        })
      );
      return auditLog;
    } catch (error) {
      // Warn Message will be sent to slack
      console.warn(
        JSON.stringify({
          level: "warn",
          msg: `Failed to archive audit log ${auditLog["Event#SubjectID#TimeStamp"]}. (User ID: ${auditLog.UserID})`,
          error: (error as Error).message,
        })
      );
      return undefined;
    }
  });

  return (await Promise.all(putRequests)).filter((r) => r !== undefined) as AuditLog[];
}

async function deleteAuditLogsFromDynamoDB(
  dynamodbClient: DynamoDBClient,
  auditLogs: AuditLog[]
): Promise<void[]> {
  /**
   * The `BatchWriteCommand` can only take up to 25 `DeleteRequest` at a time.
   */
  const chunksOfDeleteRequests = chunkArray(auditLogs, 25).map((chunk) => {
    return async () => {
      try {
        await dynamodbClient.send(
          new BatchWriteCommand({
            RequestItems: {
              [AUDIT_LOGS_DYNAMODB_TABLE_NAME ?? "unknown"]: chunk.flatMap((l) => {
                return [
                  {
                    DeleteRequest: {
                      Key: {
                        UserID: l.UserID,
                        ["Event#SubjectID#TimeStamp"]: l["Event#SubjectID#TimeStamp"],
                      },
                    },
                  },
                ];
              }),
            },
          })
        );
      } catch (error) {
        console.warn(
          JSON.stringify({
            level: "warn",
            msg: `Failed to delete audit logs from AuditLogs DynamoDB table. Audit logs: ${auditLogs
              .map((l) => `${l.UserID}:${l["Event#SubjectID#TimeStamp"]}`)
              .join(",")}.`,
            error: (error as Error).message,
          })
        );
      }
    };
  });

  return runPromisesSynchronously(chunksOfDeleteRequests);
}

function chunkArray<T>(arr: T[], size: number): T[][] {
  return Array.from({ length: Math.ceil(arr.length / size) }, (v, i) =>
    arr.slice(i * size, i * size + size)
  );
}

async function runPromisesSynchronously<T>(
  promisesToBeExecuted: (() => Promise<T>)[]
): Promise<T[]> {
  const accumulator: T[] = [];

  for (const p of promisesToBeExecuted) {
    accumulator.push(await p());
  }

  return accumulator;
}
