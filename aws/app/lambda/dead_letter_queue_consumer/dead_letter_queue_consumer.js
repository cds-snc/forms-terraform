const { 
  SQSClient, 
  ReceiveMessageCommand, 
  SendMessageCommand, 
  DeleteMessageCommand 
} = require("@aws-sdk/client-sqs");

const {
  SNSClient,
  PublishCommand,
} = require("@aws-sdk/client-sns");

const REGION = process.env.REGION;
const SQS_DEAD_LETTER_QUEUE_URL = process.env.SQS_DEAD_LETTER_QUEUE_URL;
const SQS_SUBMISSION_PROCESSING_QUEUE_URL = process.env.SQS_SUBMISSION_PROCESSING_QUEUE_URL;
const SNS_ERROR_TOPIC_ARN = process.env.SNS_ERROR_TOPIC_ARN;

exports.handler = async(event) => {

  const sqsClient = new SQSClient({
    region: REGION,
    endpoint: process.env.AWS_SAM_LOCAL ? "http://host.docker.internal:4566" : undefined,
  });

  try {
    while (true) {
      const receiveMessageCommandInput = {
        QueueUrl: SQS_DEAD_LETTER_QUEUE_URL,
      };
  
      const receiveMessageCommandOutput = await sqsClient.send(new ReceiveMessageCommand(receiveMessageCommandInput));
  
      if (receiveMessageCommandOutput.Messages) {
        const message = receiveMessageCommandOutput.Messages[0];
        
        const submissionID = message.Body;
        const sendMessageCommandInput = {
          QueueUrl: SQS_SUBMISSION_PROCESSING_QUEUE_URL,
          MessageBody: JSON.stringify({ submissionID: submissionID }),
          MessageDeduplicationId: submissionID,
          MessageGroupId: "Group-" + submissionID,
        };

        await sqsClient.send(new SendMessageCommand(sendMessageCommandInput));

        const deleteMessageCommandInput = {
          QueueUrl: SQS_DEAD_LETTER_QUEUE_URL,
          ReceiptHandle: message.ReceiptHandle
        };
  
        await sqsClient.send(new DeleteMessageCommand(deleteMessageCommandInput));
      } else {
        break;
      }
    }

    return {
      statusCode: "SUCCESS"
    };
  }
  catch (err) {
    await reportErrorToSlack(err.message);

    return {
      statusCode: "ERROR",
      error: err.message,
    };
  }

};

async function reportErrorToSlack(errorMessage) {

  const snsClient = new SNSClient({ region: REGION, endpoint: process.env.AWS_SAM_LOCAL ? "http://host.docker.internal:4566" : undefined});

  const publishCommandInput = {
    Message: `End User Forms Critical - Dead letter queue consumer: ${errorMessage}`,
    TopicArn: SNS_ERROR_TOPIC_ARN,
  };

  try {
    await snsClient.send(new PublishCommand(publishCommandInput));
  } 
  catch (err) {
    throw new Error(`Failed to report error to Slack. Reason: ${err.message}.`);
  }
}