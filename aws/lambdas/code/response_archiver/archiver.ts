import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { BatchWriteCommand, QueryCommand, QueryCommandOutput } from "@aws-sdk/lib-dynamodb";
import { S3Client, PutObjectCommand, CopyObjectCommand, DeleteObjectCommand } from "@aws-sdk/client-s3";
import { Handler } from "aws-lambda";
import { FileAttachement, getFileAttachments } from "./lib/fileAttachments.js";

const REGION = process.env.REGION;
const DYNAMODB_VAULT_TABLE_NAME = process.env.DYNAMODB_VAULT_TABLE_NAME ?? "";
const ARCHIVING_S3_BUCKET = process.env.ARCHIVING_S3_BUCKET;
const VAULT_FILE_STORAGE_S3_BUCKET = process.env.VAULT_FILE_STORAGE_S3_BUCKET;

interface FormResponse {
  formId: string;
  name: string;
  submissionId: string;
  responsesAsJson: string;
  removalDate: number;
  createdAt: number;
  confirmationCode: string;
}

export const handler: Handler = async () => {
  try {
    const dynamodb = new DynamoDBClient({
      region: REGION,
      ...(process.env.LOCALSTACK && { endpoint: "http://host.docker.internal:4566" }),
    });

    const s3Client = new S3Client({
      region: REGION,
      ...(process.env.LOCALSTACK && {
        endpoint: "http://host.docker.internal:4566",
        forcePathStyle: true,
      }),
    });

    await archiveConfirmedFormResponses(dynamodb, s3Client);

    return {
      statusCode: "SUCCESS",
    };
  } catch (error) {
    // Error Message will be sent to slack
    console.error(
      JSON.stringify({
        level: "error",
        msg: "Failed to run Form Responses Archiver.",
        error: (error as Error).message,
      })
    );

    return {
      statusCode: "ERROR",
      error: (error as Error).message,
    };
  }
}

async function archiveConfirmedFormResponses(dynamodb: DynamoDBClient, s3Client: S3Client): Promise<void> {
  const formResponses = await retrieveConfirmedFormResponses(dynamodb);

  if (formResponses.length > 0) {
    for (const formResponse of formResponses) {
      try {
        const attachment = getFileAttachments(formResponse.responsesAsJson);

        await archiveFormResponseAttachments(
          s3Client,
          formResponse.formId,
          formResponse.submissionId,
          formResponse.removalDate,
          attachment
        );

        await archiveFormResponse(
          s3Client,
          formResponse.formId,
          formResponse.submissionId,
          formResponse.responsesAsJson
        );
      } catch (error) {
        // Warn Message will be sent to slack
        console.warn(
          JSON.stringify({
            level: "warn",
            msg: `Failed to archive form response ${formResponse.submissionId}. (Form ID: ${formResponse.formId})`,
            error: (error as Error).message,
          })
        );
        // Continue to attempt to archive form responses even if one fails
      }
    }

    await deleteFormResponsesAttachmentsFromVault(s3Client, formResponses);
    await deleteFormResponsesFromVault(dynamodb, formResponses);
  }
}

async function retrieveConfirmedFormResponses(dynamodb: DynamoDBClient): Promise<FormResponse[]> {
  try {
    let formResponses: FormResponse[] = [];
    let lastEvaluatedKey = null;

    while (lastEvaluatedKey !== undefined) {
      const response: QueryCommandOutput = await dynamodb.send(new QueryCommand({
        TableName: "Vault",
        IndexName: "Archive",
        ExclusiveStartKey: lastEvaluatedKey ?? undefined,
        KeyConditionExpression: "#status = :status AND RemovalDate <= :removalDate",
        ExpressionAttributeNames: {
          "#status": "Status",
          "#name": "Name",
        },
        ExpressionAttributeValues: {
          ":status": "Confirmed",
          ":removalDate": Date.now(),
        },
        ProjectionExpression:
          "FormID,#name,SubmissionID,FormSubmission,RemovalDate,CreatedAt,ConfirmationCode",
      }));

      if (response.Items?.length) {
        formResponses = formResponses.concat(
          response.Items.map((item) => ({
            formId: item.FormID,
            name: item.Name,
            submissionId: item.SubmissionID,
            responsesAsJson: item.FormSubmission,
            removalDate: item.RemovalDate,
            createdAt: item.CreatedAt,
            confirmationCode: item.ConfirmationCode,
          }))
        );
      } else {
        lastEvaluatedKey = undefined;
      }

      lastEvaluatedKey = response.LastEvaluatedKey;
    }

    return formResponses;
  } catch (error) {
    throw new Error(`Failed to retrieve confirmed form responses. Reason: ${(error as Error).message}.`);
  }
}

async function archiveFormResponseAttachments(
  s3Client: S3Client, 
  formId: string, 
  submissionId: string, 
  removalDate: number, 
  fileAttachments: FileAttachement[]
): Promise<void> {
  try {
    const promises = fileAttachments.map((attachment) => {
      const fromUri = `${attachment.path}`;
      const toUri = `${new Date(removalDate)
        .toISOString()
        .slice(0, 10)}/${formId}/${submissionId}/${attachment.name}`;

      return s3Client.send(
        new CopyObjectCommand({
          Bucket: ARCHIVING_S3_BUCKET,
          CopySource: encodeURI(`${VAULT_FILE_STORAGE_S3_BUCKET}/${fromUri}`),
          Key: toUri,
        })
      );
    });

    await Promise.all(promises);
  } catch (error) {
    throw new Error(
      `Failed to copy form response attachments from Vault to Archiving S3 buckets. Reason: ${(error as Error).message}.`
    );
  }
}

async function archiveFormResponse(s3Client: S3Client, formId: string, submissionId: string, responsesAsJson: string) {
  try {
    await s3Client.send(new PutObjectCommand({
      Bucket: ARCHIVING_S3_BUCKET,
      Body: responsesAsJson,
      Key: `${new Date().toISOString().slice(0, 10)}/${formId}/${submissionId}.json`,
    }));
  } catch (error) {
    throw new Error(
      `Failed to put form response in Archiving S3 bucket. Reason: ${(error as Error).message}.`
    );
  }
}

async function deleteFormResponsesAttachmentsFromVault(s3Client: S3Client, formResponses: FormResponse[]) {
  try {
    for (const formResponse of formResponses) {
      let attachments = getFileAttachments(formResponse.responsesAsJson);

      const promises = attachments.map((attachment) => {
        return s3Client.send(new DeleteObjectCommand({
          Bucket: VAULT_FILE_STORAGE_S3_BUCKET,
          Key: `${attachment.path}`,
        }));
      });

      await Promise.all(promises);
    }
  } catch (error) {
    console.warn(
      JSON.stringify({
        level: "warn",
        msg: `Failed to delete form responses attachments from S3 bucket. Submissions: ${formResponses
          .map((r) => `${r.submissionId}`)
          .join(",")}.`,
        error: (error as Error).message,
      })
    );
  }
}

async function deleteFormResponsesFromVault(dynamodb: DynamoDBClient, formResponses: FormResponse[]) {
  /**
   * The `BatchWriteCommand` can only take up to 25 `DeleteRequest` at a time.
   * We have to delete 2 items from DynamoDB for each form response (12*2=24).
   */
  for (const formResponsesChunk of chunkArray(formResponses, 12)) {
    const deleteRequests = formResponsesChunk.flatMap((formResponse) => {
      return [
        {
          DeleteRequest: {
            Key: {
              FormID: formResponse.formId,
              NAME_OR_CONF: `NAME#${formResponse.name}`,
            },
          },
        },
        {
          DeleteRequest: {
            Key: {
              FormID: formResponse.formId,
              NAME_OR_CONF: `CONF#${formResponse.confirmationCode}`,
            },
          },
        },
      ];
    });

    const batchWriteCommandInput = {
      RequestItems: {
        [DYNAMODB_VAULT_TABLE_NAME]: deleteRequests,
      },
    };

    try {
      await dynamodb.send(new BatchWriteCommand(batchWriteCommandInput));
    } catch (error) {
      console.warn(
        JSON.stringify({
          level: "warn",
          msg: `Failed to delete form responses from DynamoDB. Submissions: ${formResponses
            .map((r) => `${r.submissionId}`)
            .join(",")}.`,
          error: (error as Error).message,
        })
      );
    }
  }
}

function chunkArray<T>(arr: T[], size: number): T[][] {
  return Array.from({ length: Math.ceil(arr.length / size) }, (v, i) =>
    arr.slice(i * size, i * size + size)
  );
}
