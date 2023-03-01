const { DynamoDBClient, BatchWriteItemCommand, QueryCommand } = require("@aws-sdk/client-dynamodb");

const {
  S3Client,
  PutObjectCommand,
  CopyObjectCommand,
  DeleteObjectCommand,
} = require("@aws-sdk/client-s3");

const { SNSClient, PublishCommand } = require("@aws-sdk/client-sns");
const { getFileAttachments } = require("fileAttachments");

const REGION = process.env.REGION;
const DYNAMODB_VAULT_TABLE_NAME = process.env.DYNAMODB_VAULT_TABLE_NAME;
const ARCHIVING_S3_BUCKET = process.env.ARCHIVING_S3_BUCKET;
const SNS_ERROR_TOPIC_ARN = process.env.SNS_ERROR_TOPIC_ARN;
const VAULT_FILE_STORAGE_S3_BUCKET = process.env.VAULT_FILE_STORAGE_S3_BUCKET;

exports.handler = async (event) => {
  try {
    const dynamoDb = new DynamoDBClient({
      region: REGION,
      ...(process.env.AWS_SAM_LOCAL && { endpoint: "http://host.docker.internal:4566" }),
    });

    const s3Client = new S3Client({
      region: REGION,
      ...(process.env.AWS_SAM_LOCAL && {
        endpoint: "http://host.docker.internal:4566",
        forcePathStyle: true,
      }),
    });

    await archiveConfirmedFormResponses(dynamoDb, s3Client, event.Records);

    return {
      statusCode: "SUCCESS",
    };
  } catch (err) {
    const snsClient = new SNSClient({
      region: REGION,
      ...(process.env.AWS_SAM_LOCAL && { endpoint: "http://host.docker.internal:4566" }),
    });

    await reportErrorToSlack(snsClient, err.message);

    return {
      statusCode: "ERROR",
      error: err.message,
    };
  }
};

/**
 * Archive form's responses and its associated files.
 * @param dynamoDb
 * @param s3Client
 */
async function archiveConfirmedFormResponses(dynamoDb, s3Client) {
  const formResponses = await retrieveFormResponsesToBeArchived(dynamoDb);

  if (formResponses.length > 0) {
    for (const formResponse of formResponses) {
      let attachment = getFileAttachments(formResponse.formSubmission);
      await archiveResponseFiles(
        s3Client,
        formResponse.formID,
        formResponse.submissionID,
        formResponse.removalDate,
        attachment
      );
      await saveFormResponseToS3(
        s3Client,
        formResponse.formID,
        formResponse.submissionID,
        formResponse.formSubmission
      );
    }
    await removeFormResponseFilesFromVaultStorage(s3Client, formResponses);
    await deleteFormResponsesFromDynamoDb(dynamoDb, formResponses);
  }
}

/**
 *
 * @param {*} dynamoDb
 * @returns an array of Responses
 */
async function retrieveFormResponsesToBeArchived(dynamoDb) {
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
            N: Date.now(),
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
  } catch (err) {
    throw new Error(`Failed to retrieve form responses. Reason: ${err.message}.`);
  }
}

/**
 * Archives all attachments of a given submission
 * @param  s3Client
 * @param {string} formID
 * @param {string} submissionID
 * @param {string} removalDate
 * @param  fileAttachments
 */
async function archiveResponseFiles(s3Client, formID, submissionID, removalDate, fileAttachments) {
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
  } catch (err) {
    throw new Error(`Could not copy file due to ${err.message}.`);
  }
}

/**
 *
 * @param s3Client
 * @param {string} formID
 * @param {string} submissionID
 * @param {string} formResponse
 */
async function saveFormResponseToS3(s3Client, formID, submissionID, formResponse) {
  const putObjectCommandInput = {
    Bucket: ARCHIVING_S3_BUCKET,
    Body: formResponse,
    Key: `${new Date().toISOString().slice(0, 10)}/${formID}/${submissionID}.json`,
  };

  try {
    await s3Client.send(new PutObjectCommand(putObjectCommandInput));
  } catch (err) {
    throw new Error(
      `Failed to save form response to S3 (SubmissionID = ${submissionID}). Reason: ${err.message}.`
    );
  }
}

/**
 *
 * @param s3Client
 * @param {string} formResponses
 */
async function removeFormResponseFilesFromVaultStorage(s3Client, formResponses) {
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
  } catch (err) {
    throw new Error(`Oops... Unable to delete file. Reason: ${err.message}`);
  }
}

async function deleteFormResponsesFromDynamoDb(dynamoDb, formResponses) {
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
    } catch (err) {
      throw new Error(`Failed to delete form responses from DynamoDB. Reason: ${err.message}.`);
    }
  }
}

async function reportErrorToSlack(snsClient, errorMessage) {
  const publishCommandInput = {
    Message: `End User Forms Critical - Form responses archiver: ${errorMessage}`,
    TopicArn: SNS_ERROR_TOPIC_ARN,
  };

  try {
    await snsClient.send(new PublishCommand(publishCommandInput));
  } catch (err) {
    throw new Error(`Failed to report error to Slack. Reason: ${err.message}.`);
  }
}
