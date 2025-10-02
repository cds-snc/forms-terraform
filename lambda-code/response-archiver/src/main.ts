import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { BatchWriteCommand, ScanCommand, ScanCommandOutput } from "@aws-sdk/lib-dynamodb";
import {
  S3Client,
  PutObjectCommand,
  CopyObjectCommand,
  DeleteObjectsCommand,
} from "@aws-sdk/client-s3";
import { Context, Handler } from "aws-lambda";

const DYNAMODB_VAULT_TABLE_NAME = process.env.DYNAMODB_VAULT_TABLE_NAME ?? "";
const ARCHIVING_S3_BUCKET = process.env.ARCHIVING_S3_BUCKET;
const VAULT_FILE_STORAGE_S3_BUCKET = process.env.VAULT_FILE_STORAGE_S3_BUCKET;

const PROCESSING_CHUNK_SIZE = 100;

type Attachment = {
  name: string;
  path: string;
};

type FormResponse = {
  formId: string;
  name: string;
  submissionId: string;
  responsesAsJson: string;
  createdAt: number;
  confirmationCode: string;
  submissionAttachments: Attachment[];
};

const dynamodbClient = new DynamoDBClient({
  region: process.env.REGION ?? "ca-central-1",
});

const s3Client = new S3Client({
  region: process.env.REGION ?? "ca-central-1",
});

export const handler: Handler = async (_, context) => {
  try {
    await archiveResponses(dynamodbClient, s3Client, context);

    console.log(
      JSON.stringify({
        level: "info",
        status: "success",
        msg: "Response Archiver ran successfully.",
      })
    );

    return {
      statusCode: "SUCCESS",
    };
  } catch (error) {
    // Error Message will be sent to slack
    console.error(
      JSON.stringify({
        level: "error",
        status: "failed",
        msg: "Failed to run Form Responses Archiver.",
        error: (error as Error).message,
      })
    );

    return {
      statusCode: "ERROR",
      error: (error as Error).message,
    };
  }
};

async function archiveResponses(
  dynamodbClient: DynamoDBClient,
  s3Client: S3Client,
  lambdaContext: Context
): Promise<void> {
  let lastEvaluatedKey = null;

  // Exit loop if no more items to process or lambda will time out in less than a minute
  while (lastEvaluatedKey !== undefined && lambdaContext.getRemainingTimeInMillis() >= 60000) {
    const archivableResponses = await retrieveArchivableResponses(
      dynamodbClient,
      lastEvaluatedKey ?? undefined
    );

    let fileAttachmentsToDelete: Attachment[] = [];

    for (const response of archivableResponses.responses) {
      try {
        await archiveFileAttachments(
          s3Client,
          response.formId,
          response.submissionId,
          response.submissionAttachments
        );

        await archiveResponsesAsJson(
          s3Client,
          response.formId,
          response.submissionId,
          response.responsesAsJson
        );

        fileAttachmentsToDelete = fileAttachmentsToDelete.concat(response.submissionAttachments);
      } catch (error) {
        // Warn Message will be sent to slack
        console.warn(
          JSON.stringify({
            level: "warn",
            msg: `Failed to archive response ${response.submissionId}. (Form ID: ${response.formId})`,
            error: (error as Error).message,
          })
        );

        // Continue to attempt to archive form responses even if one fails
      }
    }

    await deleteFileAttachments(s3Client, fileAttachmentsToDelete);
    await deleteResponses(dynamodbClient, archivableResponses.responses);

    lastEvaluatedKey = archivableResponses.lastEvaluatedKey;
  }
}

async function retrieveArchivableResponses(
  dynamodbClient: DynamoDBClient,
  lastEvaluatedKey?: Record<string, any>
): Promise<{ responses: FormResponse[]; lastEvaluatedKey?: Record<string, any> }> {
  try {
    const scanResults: ScanCommandOutput = await dynamodbClient.send(
      new ScanCommand({
        TableName: DYNAMODB_VAULT_TABLE_NAME,
        Limit: PROCESSING_CHUNK_SIZE,
        ExclusiveStartKey: lastEvaluatedKey,
        FilterExpression:
          "begins_with(NAME_OR_CONF, :nameOrConfPrefix) AND RemovalDate <= :removalDate",
        ProjectionExpression:
          "FormID,#name,SubmissionID,FormSubmission,CreatedAt,ConfirmationCode,SubmissionAttachments",
        ExpressionAttributeNames: {
          "#name": "Name",
        },
        ExpressionAttributeValues: {
          ":nameOrConfPrefix": "NAME#",
          ":removalDate": Date.now(),
        },
      })
    );

    return {
      responses:
        scanResults.Items?.map((item) => ({
          formId: item.FormID,
          name: item.Name,
          submissionId: item.SubmissionID,
          responsesAsJson: item.FormSubmission,
          createdAt: item.CreatedAt,
          confirmationCode: item.ConfirmationCode,
          submissionAttachments: JSON.parse(item.SubmissionAttachments ?? "[]"), // Legacy submissions don't have SubmissionAttachments in their data set
        })) ?? [],
      lastEvaluatedKey: scanResults.LastEvaluatedKey,
    };
  } catch (error) {
    throw new Error(
      `Failed to retrieve archivable responses. Reason: ${(error as Error).message}.`
    );
  }
}

async function archiveFileAttachments(
  s3Client: S3Client,
  formId: string,
  submissionId: string,
  fileAttachments: Attachment[]
): Promise<void> {
  try {
    const copyObjectRequests = fileAttachments.map((attachment) => {
      const fromUri = `${attachment.path}`;
      const toUri = `${new Date()
        .toISOString()
        .slice(0, 10)}/${formId}/${submissionId}/${submissionId}_${attachment.name}`;

      return s3Client.send(
        new CopyObjectCommand({
          Bucket: ARCHIVING_S3_BUCKET,
          CopySource: encodeURI(`${VAULT_FILE_STORAGE_S3_BUCKET}/${fromUri}`),
          Key: toUri,
        })
      );
    });

    await Promise.all(copyObjectRequests);
  } catch (error) {
    throw new Error(
      `Failed to copy file attachments from Vault to Archiving S3 bucket. Reason: ${
        (error as Error).message
      }.`
    );
  }
}

async function archiveResponsesAsJson(
  s3Client: S3Client,
  formId: string,
  submissionId: string,
  responsesAsJson: string
) {
  try {
    await s3Client.send(
      new PutObjectCommand({
        Bucket: ARCHIVING_S3_BUCKET,
        Body: responsesAsJson,
        Key: `${new Date()
          .toISOString()
          .slice(0, 10)}/${formId}/${submissionId}/${submissionId}.json`,
      })
    );
  } catch (error) {
    throw new Error(
      `Failed to save responses as JSON in Archiving S3 bucket. Reason: ${
        (error as Error).message
      }.`
    );
  }
}

async function deleteFileAttachments(s3Client: S3Client, fileAttachments: Attachment[]) {
  if (fileAttachments.length === 0) return;

  try {
    await s3Client.send(
      new DeleteObjectsCommand({
        Bucket: VAULT_FILE_STORAGE_S3_BUCKET,
        Delete: {
          Objects: fileAttachments.map((f) => ({ Key: f.path })),
        },
      })
    );
  } catch (error) {
    console.warn(
      JSON.stringify({
        level: "warn",
        msg: `Failed to delete file attachments from Vault S3 bucket. Files: ${fileAttachments
          .map((f) => `${f.path}`)
          .join(",")}.`,
        error: (error as Error).message,
      })
    );
  }
}

async function deleteResponses(dynamodbClient: DynamoDBClient, responses: FormResponse[]) {
  if (responses.length === 0) return;

  /**
   * The `BatchWriteCommand` can only take up to 25 `DeleteRequest` at a time.
   * We have to delete 2 items from DynamoDB for each form response (12*2=24).
   */
  const chunkedDeleteRequests = chunkArray(responses, 12).map((responseChunk) => {
    return async () => {
      try {
        await dynamodbClient.send(
          new BatchWriteCommand({
            RequestItems: {
              [DYNAMODB_VAULT_TABLE_NAME]: responseChunk.flatMap((r) => {
                return [
                  {
                    DeleteRequest: {
                      Key: {
                        FormID: r.formId,
                        NAME_OR_CONF: `NAME#${r.name}`,
                      },
                    },
                  },
                  {
                    DeleteRequest: {
                      Key: {
                        FormID: r.formId,
                        NAME_OR_CONF: `CONF#${r.confirmationCode}`,
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
            msg: `Failed to delete responses from Vault DynamoDB table. Responses: ${responses
              .map((r) => `${r.submissionId}`)
              .join(",")}.`,
            error: (error as Error).message,
          })
        );
      }
    };
  });

  await runPromisesSynchronously(chunkedDeleteRequests);
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
