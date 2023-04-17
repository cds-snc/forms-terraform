const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, BatchWriteCommand } = require("@aws-sdk/lib-dynamodb");
const { SNSClient, PublishCommand } = require("@aws-sdk/client-sns");

const SNS_ERROR_TOPIC_ARN = process.env.SNS_ERROR_TOPIC_ARN;

function connectToDynamo() {
  return DynamoDBDocumentClient.from(
    new DynamoDBClient({
      region: process.env.REGION ?? "ca-central-1",
      ...(process.env.AWS_SAM_LOCAL && { endpoint: "http://host.docker.internal:4566" }),
    })
  );
}

async function reportErrorToSlack(errorMessage) {
  const snsClient = new SNSClient({
    region: process.env.REGION,
    ...(process.env.AWS_SAM_LOCAL && { endpoint: "http://host.docker.internal:4566" }),
  });
  const publishCommandInput = {
    Message: `Audit Log Processing Critical - ${errorMessage}`,
    TopicArn: SNS_ERROR_TOPIC_ARN,
  };

  try {
    await snsClient.send(new PublishCommand(publishCommandInput));
  } catch (err) {
    console.log(
      `ERROR: Failed to report error to Slack. Slack Error: ${err.message}. Message to Transmit: ${errorMessage}`
    );
  }
}

exports.handler = async function (event) {
  /* 
  LogEvent contains:
  {
    userID,
    event,
    timestamp,
    subject: {type, id?},
    description,
  }
  */
  try {
    const logEvents = event.Records.map((record) => ({
      messageId: record.messageId,
      logEvent: JSON.parse(record.body),
    }));

    // Archive after 1 year
    const archiveDate = ((d) => Math.floor(d.setFullYear(d.getFullYear() + 1) / 1000))(new Date());

    const putTransactionItems = logEvents.map(({ logEvent }) => ({
      PutRequest: {
        Item: {
          UserID: logEvent.userID,
          "Event#SubjectID#TimeStamp": `${logEvent.event}#${
            logEvent.subject.id ?? logEvent.subject.type
          }#${logEvent.timestamp}`,
          Event: logEvent.event,
          Subject: `${logEvent.subject.type}${
            logEvent.subject.id ? `#${logEvent.subject.id}` : ""
          }`,
          TimeStamp: logEvent.timestamp,
          ...(logEvent.description && { Description: logEvent.description }),
          ArchiveDate: archiveDate,
        },
      },
    }));

    const dynamoDb = connectToDynamo();

    const {
      UnprocessedItems: { AuditLogs },
    } = await dynamoDb.send(
      new BatchWriteCommand({
        RequestItems: {
          AuditLogs: putTransactionItems,
        },
      })
    );

    if (typeof AuditLogs !== "undefined") {
      const unprocessedIDs = AuditLogs.map(({ PutItem: { UserID, Event, TimeStamp } }, index) => {
        // Find the original LogEvent item that has the messageID
        const [unprocessItem] = logEvents.filter(
          ({ logEvent }) =>
            logEvent.userID === UserID &&
            logEvent.event === Event &&
            logEvent.timestamp === TimeStamp
        )[0];
        if (!unprocessItem)
          throw new Error(
            `Unprocessed LogEvent could not be found. ${JSON.stringify(
              UnprocessedItems.AuditLogs[index]
            )} not found.`
          );
        return unprocessItem.messageId;
      });
      return {
        batchItemFailures: unprocessedIDs.map((id) => ({ itemIdentifier: id })),
      };
    }

    return {
      batchItemFailures: [],
    };
  } catch (error) {
    // Catastrophic Error - Fail whole batch
    reportErrorToSlack(error.message);
    console.error(error);

    return {
      batchItemFailures: event.Records.map((record) => ({ itemIdentifier: record.messageId })),
    };
  }
};
