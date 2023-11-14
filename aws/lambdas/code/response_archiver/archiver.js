import { DynamoDBClient, BatchWriteItemCommand, QueryCommand } from "@aws-sdk/client-dynamodb";

import {
  S3Client,
  PutObjectCommand,
  CopyObjectCommand,
  DeleteObjectCommand,
} from "@aws-sdk/client-s3";

import { getFileAttachments } from "./lib/fileAttachments.js";

const REGION = process.env.REGION;
const DYNAMODB_VAULT_TABLE_NAME = process.env.DYNAMODB_VAULT_TABLE_NAME;
const ARCHIVING_S3_BUCKET = process.env.ARCHIVING_S3_BUCKET;
const VAULT_FILE_STORAGE_S3_BUCKET = process.env.VAULT_FILE_STORAGE_S3_BUCKET;

export async function handler(event) {
  try {
    const dynamoDb = new DynamoDBClient({
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

    await archiveConfirmedFormResponses(dynamoDb, s3Client);

    return {
      statusCode: "SUCCESS",
    };
  } catch (error) {
    // Error Message will be sent to slack
    console.error(
      JSON.stringify({
        level: "error",
        msg: "Failed to run Form Responses Archiver.",
        error: error.message,
      })
    );

    return {
      statusCode: "ERROR",
      error: error.message,
    };
  }
}

async function archiveConfirmedFormResponses(dynamoDb, s3Client) {
  const formResponses = await retrieveConfirmedFormResponses(dynamoDb);

  if (formResponses.length > 0) {
    for (const formResponse of formResponses) {
      try {
        let attachment = getFileAttachments(formResponse.formSubmission);

        await archiveFormResponseAttachments(
          s3Client,
          formResponse.formID,
          formResponse.submissionID,
          formResponse.removalDate,
          attachment
        );

        await archiveFormResponse(
          s3Client,
          formResponse.formID,
          formResponse.submissionID,
          formResponse.formSubmission
        );
      } catch (error) {
        // Warn Message will be sent to slack
        console.warn(
          JSON.stringify({
            level: "warn",
            msg: `Failed to archive form response ${formResponse.submissionID}. (Form ID: ${formResponse.formID})`,
            error: error.message,
          })
        );
        // Continue to attempt to archive form responses even if one fails
      }
    }

    await deleteFormResponsesAttachmentsFromVault(s3Client, formResponses);
    await deleteFormResponsesFromVault(dynamoDb, formResponses);
  }
}

async function retrieveConfirmedFormResponses(dynamoDb) {
  try {
    let formResponses = [];
    let lastEvaluatedKey = null;

    while (lastEvaluatedKey !== undefined) {
      const queryCommandInput = {
        TableName: "Vault",
        IndexName: "Archive",
        ExclusiveStartKey: lastEvaluatedKey ?? undefined,
        KeyConditionExpression: "#status = :status AND RemovalDate <= :removalDate",
        ExpressionAttributeNames: {
          "#status": "Status",
          "#name": "Name",
        },
        ExpressionAttributeValues: {
          ":status": {
            S: "Confirmed",
          },
          ":removalDate": {
            N: Date.now().toString(),
          },
        },
        ProjectionExpression:
          "FormID,#name,SubmissionID,FormSubmission,RemovalDate,CreatedAt,ConfirmationCode",
      };

      const response = await dynamoDb.send(new QueryCommand(queryCommandInput));

      if (response.Items?.length) {
        formResponses = formResponses.concat(
          response.Items.map((item) => ({
            formID: item.FormID.S,
            name: item.Name.S,
            submissionID: item.SubmissionID.S,
            formSubmission: item.FormSubmission.S,
            removalDate: item.RemovalDate.N,
            createdAt: item.CreatedAt.N,
            confirmationCode: item.ConfirmationCode.S,
          }))
        );
      } else {
        lastEvaluatedKey = undefined;
      }

      lastEvaluatedKey = response.LastEvaluatedKey;
    }

    return formResponses;
  } catch (error) {
    throw new Error(`Failed to retrieve confirmed form responses. Reason: ${error.message}.`);
  }
}

async function archiveFormResponseAttachments(
  s3Client,
  formID,
  submissionID,
  removalDate,
  fileAttachments
) {
  try {
    const promises = fileAttachments.map((attachment) => {
      const fromUri = `${attachment.fileS3Path}`;
      const toUri = `${new Date(parseInt(removalDate))
        .toISOString()
        .slice(0, 10)}/${formID}/${submissionID}/${attachment.fileName}`;

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
      `Failed to copy form response attachments from Vault to Archiving S3 buckets. Reason: ${error.message}.`
    );
  }
}

async function archiveFormResponse(s3Client, formID, submissionID, formResponse) {
  const putObjectCommandInput = {
    Bucket: ARCHIVING_S3_BUCKET,
    Body: formResponse,
    Key: `${new Date().toISOString().slice(0, 10)}/${formID}/${submissionID}.json`,
  };

  try {
    await s3Client.send(new PutObjectCommand(putObjectCommandInput));
  } catch (error) {
    throw new Error(
      `Failed to put form response in Archiving S3 bucket. Reason: ${error.message}.`
    );
  }
}

async function deleteFormResponsesAttachmentsFromVault(s3Client, formResponses) {
  try {
    for (const formResponse of formResponses) {
      let attachments = getFileAttachments(formResponse.formSubmission);

      const promises = attachments.map((attachment) => {
        const commandInput = {
          Bucket: VAULT_FILE_STORAGE_S3_BUCKET,
          Key: `${attachment.fileS3Path}`,
        };

        return s3Client.send(new DeleteObjectCommand(commandInput));
      });

      await Promise.all(promises);
    }
  } catch (error) {
    console.warn(
      JSON.stringify({
        level: "warn",
        msg: `Failed to delete form responses attachments from S3 bucket. Submissions: ${formResponses
          .map((r) => `${r.submissionID}`)
          .join(",")}.`,
        error: error.message,
      })
    );
  }
}

async function deleteFormResponsesFromVault(dynamoDb, formResponses) {
  const chunks = (arr, size) =>
    Array.from({ length: Math.ceil(arr.length / size) }, (v, i) =>
      arr.slice(i * size, i * size + size)
    );

  /**
   * The `BatchWriteItemCommand` can only take up to 25 `DeleteRequest` at a time.
   * We have to delete 2 items from DynamoDB for each form response (12*2=24).
   */
  for (const formResponsesChunk of chunks(formResponses, 12)) {
    const deleteRequests = formResponsesChunk.flatMap((formResponse) => {
      return [
        {
          DeleteRequest: {
            Key: {
              FormID: {
                S: formResponse.formID,
              },
              NAME_OR_CONF: {
                S: `NAME#${formResponse.name}`,
              },
            },
          },
        },
        {
          DeleteRequest: {
            Key: {
              FormID: {
                S: formResponse.formID,
              },
              NAME_OR_CONF: {
                S: `CONF#${formResponse.confirmationCode}`,
              },
            },
          },
        },
      ];
    });

    const batchWriteItemCommandInput = {
      RequestItems: {
        [DYNAMODB_VAULT_TABLE_NAME]: deleteRequests,
      },
    };

    try {
      await dynamoDb.send(new BatchWriteItemCommand(batchWriteItemCommandInput));
    } catch (error) {
      console.warn(
        JSON.stringify({
          level: "warn",
          msg: `Failed to delete form responses from DynamoDB. Submissions: ${formResponses
            .map((r) => `${r.submissionID}`)
            .join(",")}.`,
          error: error.message,
        })
      );
    }
  }
}
