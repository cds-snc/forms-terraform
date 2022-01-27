const {
  DynamoDBClient,
  QueryCommand,
  BatchWriteItemCommand,
} = require("@aws-sdk/client-dynamodb");

const {
  S3Client,
  PutObjectCommand,
} = require("@aws-sdk/client-s3");

const {
  SNSClient,
  PublishCommand,
} = require("@aws-sdk/client-sns");

const REGION = process.env.REGION;
const DYNAMODB_VAULT_TABLE_NAME = process.env.DYNAMODB_VAULT_TABLE_NAME;
const DYNAMODB_VAULT_INDEX_NAME = process.env.DYNAMODB_VAULT_INDEX_NAME;
const ARCHIVING_S3_BUCKET = process.env.ARCHIVING_S3_BUCKET;
const SNS_ERROR_TOPIC_ARN = process.env.SNS_ERROR_TOPIC_ARN;

// We are limited by the `BatchWriteItemCommand` (we use to delete items from DynamoDB) that can only take 25 `DeleteRequest` at a time
const PROCESSING_BATCH_SIZE = 25;

exports.handler = async(event) => {

  try {
    const dynamoDb = new DynamoDBClient({ region: REGION, endpoint: process.env.AWS_SAM_LOCAL ? "http://host.docker.internal:4566" : undefined});
    const s3Client = new S3Client({
      region: REGION,
      endpoint: process.env.AWS_SAM_LOCAL ? "http://host.docker.internal:4566" : undefined,
      forcePathStyle: process.env.AWS_SAM_LOCAL ? true : undefined
    });

    await archiveConsumedFormResponses(dynamoDb, s3Client);

    return {
      statusCode: "SUCCESS"
    };
  }
  catch (err) {
    const snsClient = new SNSClient({ region: REGION, endpoint: process.env.AWS_SAM_LOCAL ? "http://host.docker.internal:4566" : undefined});

    await reportErrorToSlack(snsClient, err.message);

    return {
      statusCode: "ERROR",
      error: err.message,
    };
  }

};

async function archiveConsumedFormResponses(dynamoDb, s3Client) {
  let lastReadResponse = null;

  while (lastReadResponse !== undefined) {
    const response = await getConsumedFormResponses(dynamoDb, lastReadResponse === null ? undefined : lastReadResponse);

    if (response.formResponses.length > 0) {
      for (const formResponse of response.formResponses) {
        await saveFormResponseToS3(s3Client, formResponse.FormID.S, formResponse.SubmissionID.S, formResponse.FormSubmission.S);
      }

      await deleteFormResponsesFromDynamoDb(dynamoDb, response.formResponses);
    }

    lastReadResponse = response.lastReadResponse;
  }
}

async function getConsumedFormResponses(dynamoDb, lastReadResponse = undefined) {
  const queryCommandInput = {
    TableName: DYNAMODB_VAULT_TABLE_NAME,
    IndexName: DYNAMODB_VAULT_INDEX_NAME,
    Limit: PROCESSING_BATCH_SIZE,
    ExclusiveStartKey: lastReadResponse,
    KeyConditionExpression: "Retrieved = :isRetrieved",
    ExpressionAttributeValues: { ":isRetrieved": { N: "1" } },
    ProjectionExpression: "FormID, SubmissionID, FormSubmission",
  };

  try {
    const queryCommandOutput = await dynamoDb.send(new QueryCommand(queryCommandInput));

    return {
      formResponses: queryCommandOutput.Items,
      lastReadResponse: queryCommandOutput.LastEvaluatedKey,
    };
  }
  catch (err) {
    throw new Error(`Failed to retrieve consumed form responses. Reason: ${err.message}.`);
  }
}

async function saveFormResponseToS3(s3Client, formID, submissionID, formResponse) {
  const putObjectCommandInput = {
    Bucket: ARCHIVING_S3_BUCKET,
    Body: formResponse,
    Key: `${new Date().toISOString().slice(0, 10)}/${formID}/${submissionID}.json`,
  };

  try {
    await s3Client.send(new PutObjectCommand(putObjectCommandInput));
  }
  catch (err) {
    throw new Error(`Failed to save form response to S3 (SubmissionID = ${submissionID}). Reason: ${err.message}.`);
  }
}

async function deleteFormResponsesFromDynamoDb(dynamoDb, formResponses) {
  const deleteRequests = formResponses.reduce((accumulator, currentValue) => {
    const deleteRequest = {
      "DeleteRequest": {
        "Key": {
          "FormID": {
            "S": currentValue.FormID.S
          },
          "SubmissionID": {
            "S": currentValue.SubmissionID.S
          }
        }
      }
    };
    return [...accumulator, ...[deleteRequest]];
  }, []);

  const batchWriteItemCommandInput = {
    RequestItems: {
      [DYNAMODB_VAULT_TABLE_NAME]: deleteRequests
    },
  };

  try {
    await dynamoDb.send(new BatchWriteItemCommand(batchWriteItemCommandInput));
  }
  catch (err) {
    throw new Error(`Failed to delete form responses from DynamoDB. Reason: ${err.message}.`);
  }
}

async function reportErrorToSlack(snsClient, errorMessage) {
  
  const publishCommandInput = {
    Message: `End User Forms Critical - Form responses archiver: ${errorMessage}`,
    TopicArn: SNS_ERROR_TOPIC_ARN,
  };

  try {
    await snsClient.send(new PublishCommand(publishCommandInput));
  } 
  catch (err) {
    throw new Error(`Failed to report error to Slack. Reason: ${err.message}.`);
  }
}