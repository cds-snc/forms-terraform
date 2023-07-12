const {
  SQSClient,
  ReceiveMessageCommand,
  SendMessageCommand,
  DeleteMessageCommand,
} = require("@aws-sdk/client-sqs");

const REGION = process.env.REGION;
const SQS_DEAD_LETTER_QUEUE_URL = process.env.SQS_DEAD_LETTER_QUEUE_URL;
const SQS_SUBMISSION_PROCESSING_QUEUE_URL = process.env.SQS_SUBMISSION_PROCESSING_QUEUE_URL;

exports.handler = async () => {
  const sqsClient = new SQSClient({
    region: REGION,
    ...(process.env.AWS_SAM_LOCAL && { endpoint: "http://host.docker.internal:4566" }),
  });
  const receiveMessageCommandInput = {
    QueueUrl: SQS_DEAD_LETTER_QUEUE_URL,
  };
  var messagesToProcess = true;

  try {
    while (messagesToProcess) {
      const receiveMessageCommandOutput = await sqsClient.send(
        new ReceiveMessageCommand(receiveMessageCommandInput)
      );

      if (receiveMessageCommandOutput.Messages) {
        const message = receiveMessageCommandOutput.Messages[0];

        const { submissionID } = JSON.parse(message.Body);
        const sendMessageCommandInput = {
          QueueUrl: SQS_SUBMISSION_PROCESSING_QUEUE_URL,
          MessageBody: JSON.stringify({
            submissionID: submissionID,
          }),
          MessageDeduplicationId: submissionID,
          MessageGroupId: "Group-" + submissionID,
        };

        await sqsClient.send(new SendMessageCommand(sendMessageCommandInput));

        const deleteMessageCommandInput = {
          QueueUrl: SQS_DEAD_LETTER_QUEUE_URL,
          ReceiptHandle: message.ReceiptHandle,
        };

        await sqsClient.send(new DeleteMessageCommand(deleteMessageCommandInput));
      } else {
        messagesToProcess = false;
      }
    }

    return {
      statusCode: "SUCCESS",
    };
  } catch (err) {
    // Report Errorr to Slack
    console.error(
      JSON.stringify({
        level: "error",
        msg: "Reliability DLQ could not process waiting messages.",
        error: err.message,
      })
    );

    return {
      statusCode: "ERROR",
      error: err.message,
    };
  }
};
