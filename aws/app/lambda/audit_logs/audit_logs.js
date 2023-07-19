const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, BatchWriteCommand } = require("@aws-sdk/lib-dynamodb");

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

    const dynamoDb = DynamoDBDocumentClient.from(
      new DynamoDBClient({
        region: process.env.REGION ?? "ca-central-1",
        ...(process.env.AWS_SAM_LOCAL && { endpoint: "http://host.docker.internal:4566" }),
      })
    );

    const {
      UnprocessedItems: { AuditLogs },
    } = await dynamoDb.send(
      new BatchWriteCommand({
        RequestItems: {
          AuditLogs: putTransactionItems,
        },
      })
    );

    console.log(
      JSON.stringify({
        msg: "AuditLogs",
        audit_logs: JSON.stringify(AuditLogs),
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
              AuditLogs[index]
            )} not found.`
          );

        return unprocessItem.messageId;
      });

      console.warn(
        JSON.stringify({
          level: "warn",
          msg: `Failed to process ${unprocessedIDs.length} log events. List of unprocessed IDs: ${unprocessedIDs.join(',')}.`,
          error: error.message,
        })
      );

      return {
        batchItemFailures: unprocessedIDs.map((id) => ({ itemIdentifier: id })),
      };
    }

    return {
      batchItemFailures: [],
    };
  } catch (error) {
    // Catastrophic Error - Fail whole batch -- Error Message will be sent to slack
    console.error(
      JSON.stringify({
        level: "error",
        msg: "Failed to run Audit Logs Processor.",
        error: error.message,
      })
    );

    return {
      batchItemFailures: event.Records.map((record) => ({ itemIdentifier: record.messageId })),
    };
  }
};
