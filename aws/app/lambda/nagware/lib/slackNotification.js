const { SNSClient, PublishCommand } = require("@aws-sdk/client-sns");

const snsClient = new SNSClient({
  region: process.env.REGION,
  ...(process.env.AWS_SAM_LOCAL && { endpoint: "http://host.docker.internal:4566" }),
});

async function notifyFormsTeam(formID, age) {
  try {
    await snsClient.send(new PublishCommand({
      Message: `End User Forms Warning - ${age} days old form response was detected. Form ID : ${formID}.`,
      TopicArn: process.env.SNS_ERROR_TOPIC_ARN,
    }));
  } catch (error) {
    throw new Error(`Failed to notify Forms team that an old form response was detected. Reason: ${error.message}.`);
  }
}

async function reportError(errorMessage) {
  try {
    await snsClient.send(new PublishCommand({
      Message: `End User Forms Critical - Form responses archiver: ${errorMessage}`,
      TopicArn: process.env.SNS_ERROR_TOPIC_ARN,
    }));
  } catch (error) {
    throw new Error(`Failed to report error. Reason: ${error.message}.`);
  }
}

module.exports = {
  notifyFormsTeam,
  reportError,
};