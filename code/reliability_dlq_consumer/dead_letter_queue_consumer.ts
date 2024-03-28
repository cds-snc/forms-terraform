import {
  SQSClient,
  ReceiveMessageCommand,
  SendMessageCommand,
  DeleteMessageCommand,
} from "@aws-sdk/client-sqs";

const REGION = process.env.REGION;
const SQS_DEAD_LETTER_QUEUE_URL = process.env.SQS_DEAD_LETTER_QUEUE_URL;
const SQS_SUBMISSION_PROCESSING_QUEUE_URL = process.env.SQS_SUBMISSION_PROCESSING_QUEUE_URL;

export async function handler() {
  const sqsClient = new SQSClient({
    region: REGION,
    ...(process.env.LOCALSTACK === "true" && { endpoint: "http://host.docker.internal:4566" }),
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

        if (!message.Body) throw new Error("Message body is empty.");

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
    if (err instanceof Error) {
      // Report Errorr to Slack
      console.error(
        JSON.stringify({
          level: "error",
          severity: 2,
          msg: "Reliability DLQ could not process waiting messages.",
          error: err.message,
        })
      );

      return {
        statusCode: "ERROR",
        error: err.message,
      };
    } else {
      // We don't know what type of error this is, so we throw it
      throw err;
    }
  }
}
