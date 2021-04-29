const { SQSClient, SendMessageCommand } = require("@aws-sdk/client-sqs");
const { DynamoDBClient, PutItemCommand, UpdateItemCommand } = require("@aws-sdk/client-dynamodb");
const uuid = require("uuid");

const REGION = process.env.REGION;
const db = new DynamoDBClient({ region: REGION });
const sqs = new SQSClient({ region: REGION });

// Store questions with responses
exports.handler = async function (event) {
  try {
    const formData = event;
    const submissionID = uuid.v4();
    //-----------

    return saveData(submissionID, formData)
      .then(() => {
        return sendData(submissionID);
      })
      .then(async (receiptID) => {
        // Update DB entry for receipt ID
        await saveReceipt(submissionID, receiptID);
        console.log(
          `SQS Message successfully created with reciept ID ${receiptID} for submission ID ${submissionID}`
        );
        return { status: true };
      })
      .catch((err) => {
        console.error(err);
        console.error(`Form Submission with ID ${submissionID} errored during submission`);
        return { status: false };
      });
    //----------
  } catch (err) {
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
  const DBParams = {
    TableName: "ReliabilityQueue",
    Item: {
      SubmissionID: { S: submissionID },
      SendReceipt: { S: "unknown" },
      FormData: { S: JSON.stringify(formData) },
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
    console.warn(`Unable to update receipt ID on submissionID: ${submissionID}`);
    console.warn(err);
  }
};
