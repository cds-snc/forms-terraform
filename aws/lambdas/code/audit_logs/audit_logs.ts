import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, BatchWriteCommand } from "@aws-sdk/lib-dynamodb";
import { Handler, SQSEvent } from "aws-lambda";

type LogEvent = {
  userID: string;
  event: string;
  timestamp: string;
  subject: { type: string; id?: string };
  description: string;
};

const awsProperties = {
  region: process.env.REGION ?? "ca-central-1",
  ...(process.env.LOCALSTACK === "true" && {
    endpoint: "http://host.docker.internal:4566",
  }),
};

const warnOnEvents = [
  // Form Events
  "GrantFormAccess",
  "RevokeFormAccess",
  // User Events
  "UserActivated",
  "UserDeactivated",
  "UserTooManyFailedAttempts",
  "GrantPrivilege",
  "RevokePrivilege",
  // Application events
  "EnableFlag",
  "DisableFlag",
  "ChangeSetting",
  "CreateSetting",
  "DeleteSetting",
];

const notifyOnEvent = async (logEvents: Array<LogEvent>) => {
  const eventsToNotify = logEvents.filter((logEvent) => warnOnEvents.includes(logEvent.event));
  eventsToNotify.forEach((logEvent) =>
    console.warn(
      JSON.stringify({
        level: "warn",
        msg: `User ${logEvent.userID} performed ${logEvent.event} on ${logEvent.subject?.type} ${
          logEvent.subject.id ?? `with id ${logEvent.subject.id}.`
        }${logEvent.description ? "\n".concat(logEvent.description) : ""}`,
      })
    )
  );
};

export const handler: Handler = async (event: SQSEvent) => {
  try {
    const logEvents = event.Records.map((record) => ({
      messageId: record.messageId,
      logEvent: JSON.parse(record.body) as LogEvent,
    }));

    // Warn on events that should be notified
    await notifyOnEvent(logEvents.map((event) => event.logEvent));

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
          Status: "Archivable"
        },
      },
    }));

    const uniquePutTransactionItems = [
      ...new Map(
        putTransactionItems.map((v) => [
          JSON.stringify([
            v.PutRequest.Item.UserID,
            v.PutRequest.Item["Event#SubjectID#TimeStamp"],
          ]),
          v,
        ])
      ).values(),
    ];

    if (putTransactionItems.length !== uniquePutTransactionItems.length) {
      // Find duplicated items that were removed

      // clone array so the original is not modified
      const clonedPutTransactionItems = [...putTransactionItems];

      uniquePutTransactionItems.forEach((u) => {
        const itemIndex = clonedPutTransactionItems.findIndex(
          (o) =>
            o.PutRequest.Item.UserID === u.PutRequest.Item.UserID &&
            o.PutRequest.Item["Event#SubjectID#TimeStamp"] ===
              u.PutRequest.Item["Event#SubjectID#TimeStamp"]
        );
        // If it exists, remove it from the cloned array so we are only left with duplicates
        if (itemIndex >= 0) {
          clonedPutTransactionItems.splice(itemIndex, 1);
        }
      });

      console.warn(
        JSON.stringify({
          level: "warn",
          severity: 3,
          msg: `Duplicate log events were detected and removed. List of duplicate events: ${JSON.stringify(
            clonedPutTransactionItems
          )}`,
        })
      );
    }

    const dynamoDb = DynamoDBDocumentClient.from(new DynamoDBClient(awsProperties));

    const { UnprocessedItems: { AuditLogs = [], ...UnprocessedItems } = {} } = await dynamoDb.send(
      new BatchWriteCommand({
        RequestItems: {
          AuditLogs: uniquePutTransactionItems,
        },
      })
    );

    if (AuditLogs.length > 0) {
      console.log(AuditLogs);
      const unprocessedIDs = AuditLogs.map(({ PutRequest: { Item } = {} }, index) => {
        // Find the original LogEvent item that has the messageID
        const unprocessedItem = logEvents.filter(
          ({ logEvent }) =>
            logEvent.userID === Item?.UserID &&
            logEvent.event === Item?.Event &&
            logEvent.timestamp === Item?.TimeStamp
        )[0];

        if (!unprocessedItem)
          throw new Error(
            `Unprocessed LogEvent could not be found. ${JSON.stringify(
              AuditLogs[index]
            )} not found.`
          );

        return unprocessedItem.messageId;
      });

      console.error(
        JSON.stringify({
          level: "error",
          severity: 1,
          msg: `Failed to process ${
            unprocessedIDs.length
          } log events. List of unprocessed IDs: ${unprocessedIDs.join(",")}.`,
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
        severity: 1,
        msg: "Failed to run Audit Logs Processor.",
        error: (error as Error).message,
      })
    );

    return {
      batchItemFailures: event.Records.map((record) => ({ itemIdentifier: record.messageId })),
    };
  }
};
