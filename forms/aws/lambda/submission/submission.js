const { SQSClient, SendMessageCommand } = require("@aws-sdk/client-sqs");
const { DynamoDBClient, PutItemCommand } = require("@aws-sdk/client-dynamodb");
const uuid = require("uuid");

const REGION = process.env.REGION;

// Store questions with responses
exports.handler = async function (event) {
  try {
    const formData = event;
    const submissionID = uuid.v4();
    //-----------
    return sendData(submissionID)
      .then(async (receiptID) => {
        console.log(`SQS Message successfully created with ID ${receiptID}`);
        await saveData(submissionID, receiptID, formData);
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
    const sqs = new SQSClient({ region: REGION });
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

const saveData = async (submissionID, sendReceipt, formData) => {
  try {
    const db = new DynamoDBClient({ region: REGION });
    const DBParams = {
      TableName: "ReliabilityQueue",
      Item: {
        SubmissionID: { S: submissionID },
        SendReceipt: { S: sendReceipt },
        Data: { S: JSON.stringify(formData) },
      },
    };
    //save data to DynamoDB
    await db.send(new PutItemCommand(DBParams));
  } catch (err) {
    throw Error(err);
  }
};
