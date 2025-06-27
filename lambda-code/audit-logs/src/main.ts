import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, BatchWriteCommand } from "@aws-sdk/lib-dynamodb";
import { Handler, SQSEvent } from "aws-lambda";
import type { BatchWriteCommandOutput } from "@aws-sdk/lib-dynamodb";
import AWSXRay from "aws-xray-sdk-core";

type LogEvent = {
  userId: string;
  event: string;
  timestamp: string;
  subject: { type: string; id?: string };
  description: string;
};

type TransactionRequest = {
  PutRequest: {
    Item: {
      UserID: string;
      "Event#SubjectID#TimeStamp": string;
      Event: string;
      Subject: string;
      TimeStamp: string;
      description?: string;
      Status: string;
    };
  };
};

const awsProperties = {
  region: process.env.REGION ?? "ca-central-1",
};

const AppAuditLogArn = process.env.APP_AUDIT_LOGS_SQS_ARN;
const ApiAuditLogArn = process.env.API_AUDIT_LOGS_SQS_ARN;

const warnOnEvents = [
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
        msg: `User ${logEvent.userId} performed ${logEvent.event} on ${logEvent.subject?.type} ${
          logEvent.subject.id ?? `with id ${logEvent.subject.id}.`
        }${logEvent.description ? "\n".concat(logEvent.description) : ""}`,
      })
    )
  );
};

const detectAndRemoveDuplicateEvents = (transactionItems: TransactionRequest[]) => {
  const uniqueTransactionItems = [
    ...new Map(
      transactionItems.map((v) => [
        JSON.stringify([v.PutRequest.Item.UserID, v.PutRequest.Item["Event#SubjectID#TimeStamp"]]),
        v,
      ])
    ).values(),
  ];

  if (transactionItems.length !== uniqueTransactionItems.length) {
    // Find duplicated items that were removed

    // clone array so the original is not modified
    const clonedPutTransactionItems = [...transactionItems];

    uniqueTransactionItems.forEach((u) => {
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

  return uniqueTransactionItems;
};

const detectUnprocessedItems = (
  unprocessedItems: BatchWriteCommandOutput["UnprocessedItems"],
  logEvents: Array<{ logEvent: LogEvent; messageId: string }>
) => {
  let batchItemFailures: { itemIdentifier: string }[] = [];

  // If there are no unprocessed items, return empty array
  if (!unprocessedItems) return batchItemFailures;

  for (const [tableName, items] of Object.entries(unprocessedItems)) {
    if (items.length > 0) {
      console.log(items);
      const unprocessedIDs = items.map(({ PutRequest: { Item } = {} }, index) => {
        // Find the original LogEvent item that has the messageID
        const unprocessedItem = logEvents.filter(
          ({ logEvent }) =>
            logEvent.userId === Item?.UserID &&
            logEvent.event === Item?.Event &&
            logEvent.timestamp === Item?.TimeStamp
        )[0];

        if (!unprocessedItem)
          throw new Error(
            `Unprocessed ${tableName} Event could not be found. ${JSON.stringify(
              items[index]
            )} not found.`
          );

        return unprocessedItem.messageId;
      });

      console.error(
        JSON.stringify({
          level: "error",
          severity: 2,
          msg: `Failed to process ${
            items.length
          } ${tableName} events. List of unprocessed items: ${JSON.stringify(items)}`,
        })
      );
      batchItemFailures.push(...unprocessedIDs.map((id) => ({ itemIdentifier: id })));
    }
  }
  return { batchItemFailures };
};

const buildTransactionItems = (
  logEvents: Array<{
    logEvent: LogEvent;
    messageId: string;
    eventSourceARN: string;
  }>
) => {
  return logEvents.reduce(
    (
      acc: {
        appAuditLogTransactions: TransactionRequest[];
        apiAuditLogTransactions: TransactionRequest[];
      },
      { logEvent, eventSourceARN }
    ) => {
      const item = {
        PutRequest: {
          Item: {
            UserID: logEvent.userId,
            "Event#SubjectID#TimeStamp": `${logEvent.event}#${
              logEvent.subject.id ?? logEvent.subject.type
            }#${logEvent.timestamp}`,
            Event: logEvent.event,
            Subject: `${logEvent.subject.type}${
              logEvent.subject.id ? `#${logEvent.subject.id}` : ""
            }`,
            TimeStamp: logEvent.timestamp,
            ...(logEvent.description && { Description: logEvent.description }),
            Status: "Archivable",
          },
        },
      };
      switch (eventSourceARN) {
        case AppAuditLogArn:
          acc.appAuditLogTransactions.push(item);
          return acc;
        case ApiAuditLogArn:
          acc.apiAuditLogTransactions.push(item);
          return acc;
        default:
          throw new Error(`Unknown event source ARN: ${eventSourceARN}`);
      }
    },
    { appAuditLogTransactions: [], apiAuditLogTransactions: [] }
  );
};

const dynamoDb = AWSXRay.captureAWSv3Client(
  DynamoDBDocumentClient.from(new DynamoDBClient(awsProperties))
);
export const handler: Handler = async (event: SQSEvent) => {
  try {
    const logEvents = event.Records.map((record) => {
      const logEvent = JSON.parse(record.body);
      // App currently does not use userId, but userID
      // Opening an issue to correct
      logEvent.userId = logEvent.userId ?? logEvent.userID;

      return {
        messageId: record.messageId,
        eventSourceARN: record.eventSourceARN,
        logEvent: logEvent as LogEvent,
      };
    });

    // Warn on App events that should be notified
    await notifyOnEvent(
      logEvents
        .filter((event) => event.eventSourceARN === AppAuditLogArn)
        .map((event) => event.logEvent)
    );

    const { apiAuditLogTransactions, appAuditLogTransactions } = buildTransactionItems(logEvents);

    const { UnprocessedItems } = await dynamoDb.send(
      new BatchWriteCommand({
        RequestItems: {
          ...(appAuditLogTransactions.length && {
            AuditLogs: detectAndRemoveDuplicateEvents(appAuditLogTransactions),
          }),
          ...(apiAuditLogTransactions.length && {
            ApiAuditLogs: detectAndRemoveDuplicateEvents(apiAuditLogTransactions),
          }),
        },
      })
    );

    return detectUnprocessedItems(UnprocessedItems, logEvents);
  } catch (error) {
    // Catastrophic Error - Fail whole batch -- Error Message will be sent to slack
    console.error(
      JSON.stringify({
        level: "error",
        severity: 2,
        msg: "Failed to run Audit Logs Processor.",
        error: (error as Error).message,
      })
    );

    return {
      batchItemFailures: event.Records.map((record) => ({ itemIdentifier: record.messageId })),
    };
  }
};
