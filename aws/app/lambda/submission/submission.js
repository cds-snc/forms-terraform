const { SQSClient, SendMessageCommand } = require("@aws-sdk/client-sqs");
const { DynamoDBClient, PutItemCommand, UpdateItemCommand } = require("@aws-sdk/client-dynamodb");
const uuid = require("uuid");

const REGION = process.env.REGION;
const db = new DynamoDBClient({ region: REGION, endpoint: process.env.AWS_SAM_LOCAL ? "http://host.docker.internal:4566": undefined});
const sqs = new SQSClient({ region: REGION, endpoint: process.env.AWS_SAM_LOCAL? "http://host.docker.internal:4566": undefined});

const formatError = (err) => {
  return typeof err === "object" ? JSON.stringify(err) : err;
};

// Store questions with responses
exports.handler = async function (event) {
  const submissionID = uuid.v4();

  try {
    const formData = event;

    //-----------
    await saveData(submissionID, formData)
    const receiptID = await sendData(submissionID)
    // Update DB entry for receipt ID
    await saveReceipt(submissionID, receiptID);
    console.log(
        `{"status": "success", "sqsMessage": "${receiptID}", "submissionID": "${submissionID}"}`
    );
    return { status: true };

    //----------
  } catch (err) {
    console.error(
      `{"status": "failed", "submissionID": "${
        submissionID ? submissionID : "Not yet created"
      }", "error": "${formatError(err)}"}`
    );
    return { status: false };
  }
};

const sendData = async (submissionID) => {
  try {
    const SQSParams = {
      MessageBody: JSON.stringify({
        submissionID: submissionID,
      }),
      MessageDeduplicationId: submissionID,
      MessageGroupId: "Group-" + submissionID,
      QueueUrl: process.env.SQS_URL,
    };

    const queueResponse = await sqs.send(new SendMessageCommand(SQSParams));
    return queueResponse.MessageId;
  } catch (err) {
    throw Error(err);
  }
};

const saveData = async (submissionID, formData) => {
  const formSubmission = typeof formData === "string" ? formData : JSON.stringify(formData);

  const DBParams = {
    TableName: "ReliabilityQueue",
    Item: {
      SubmissionID: { S: submissionID },
      FormID: { S: formData.formID },
      SendReceipt: { S: "unknown" },
      FormSubmissionLanguage: {S: formData.language},
      FormData: { S: formSubmission },
    },
  };
  //save data to DynamoDB
  await db.send(new PutItemCommand(DBParams));
};

const saveReceipt = async (submissionID, receiptID) => {
  try {
    const DBParams = {
      TableName: "ReliabilityQueue",
      Key: {
        SubmissionID: { S: submissionID },
      },
      UpdateExpression: "SET SendReceipt = :receipt",
      ExpressionAttributeValues: {
        ":receipt": { S: receiptID },
      },
    };
    //save data to DynamoDB
    await db.send(new UpdateItemCommand(DBParams));
  } catch (err) {
    console.warn(`{status: warn, submissionID: ${submissionID}, warning: ${formatError(err)}}`);
  }
};
