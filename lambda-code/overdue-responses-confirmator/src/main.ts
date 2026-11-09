import { BatchExecuteStatementCommand, type NativeAttributeValue, QueryCommand, type QueryCommandOutput } from "@aws-sdk/lib-dynamodb";
import { EitherAsyncUtils, type LambdaInvocationContextualLogger, lambdaWithValidatedEventAndContextualLogger } from "common";
import { EitherAsync } from "purify-ts";
import z from "zod";
import { dynamodbClient } from "./lib/awsServicesConnector.ts";

const DEFAULT_AGE_IN_DAYS_AFTER_RESPONSE_CONSIDERED_OVERDUE = 45;

const lambdaEventSchema = z.object({
  formId: z.cuid2(),
  ageInDaysAfterResponseConsideredOverdue: z.uint32().optional(),
});

type OverdueResponsesConfirmatorPayload = z.infer<typeof lambdaEventSchema>;

type OverdueResponse = {
  name: string;
  createdAt: number;
};

export const handler = lambdaWithValidatedEventAndContextualLogger<OverdueResponsesConfirmatorPayload, void>(lambdaEventSchema, ({ event, contextualLogger }) => {
  const selectedAgeInDaysAfterResponseConsideredOverdue = event.ageInDaysAfterResponseConsideredOverdue ?? DEFAULT_AGE_IN_DAYS_AFTER_RESPONSE_CONSIDERED_OVERDUE;

  contextualLogger.addMetadata("formId", event.formId);
  contextualLogger.addMetadata("ageInDaysAfterResponseConsideredOverdue", `${selectedAgeInDaysAfterResponseConsideredOverdue}`);

  return retrieveAndConfirmAllOverdueResponses(event.formId, selectedAgeInDaysAfterResponseConsideredOverdue, contextualLogger)
    .ifRight(({ numberOfConfirmedOverdueResponses, oldestOverdueResponseDate, newestOverdueResponseDate }) =>
      contextualLogger.log({
        level: "warn", // Set to WARN in order to receive the log in Slack
        message: buildSummaryLogMessage({
          formId: event.formId,
          ageInDaysAfterResponseConsideredOverdue: selectedAgeInDaysAfterResponseConsideredOverdue,
          numberOfConfirmedOverdueResponses,
          oldestOverdueResponseDate,
          newestOverdueResponseDate,
        }),
      }),
    )
    .void()
    .ifLeft((error) => contextualLogger.log({ level: "error", message: "No problemo... just a minor system malfunction.\n\nI'll be back!", error }));
});

function retrieveAndConfirmAllOverdueResponses(
  formId: string,
  ageInDaysAfterResponseConsideredOverdue: number,
  contextualLogger: LambdaInvocationContextualLogger,
): EitherAsync<Error, { numberOfConfirmedOverdueResponses: number; oldestOverdueResponseDate?: Date; newestOverdueResponseDate?: Date }> {
  function retrieveAndConfirmAllOverdueResponsesWithRecursion(
    numberOfConfirmedOverdueResponses: number = 0,
    oldestOverdueResponseDate?: Date,
    newestOverdueResponseDate?: Date,
    lastEvaluatedKey?: Record<string, NativeAttributeValue>,
  ): EitherAsync<Error, { numberOfConfirmedOverdueResponses: number; oldestOverdueResponseDate?: Date; newestOverdueResponseDate?: Date }> {
    return retrieveOverdueResponses(formId, ageInDaysAfterResponseConsideredOverdue, lastEvaluatedKey)
      .chain(EitherAsyncUtils.ifRightAsync(({ overdueResponses }) => confirmOverdueResponses(formId, overdueResponses)))
      .chain(({ overdueResponses, lastEvaluatedKey }) => {
        const nextNumberOfConfirmedOverdueResponses = numberOfConfirmedOverdueResponses + overdueResponses.length;

        let nextOldestOverdueResponseDate = oldestOverdueResponseDate;
        let nextNewestOverdueResponseDate = newestOverdueResponseDate;

        if (overdueResponses.length > 0) {
          const firstOverdueResponseDate = new Date(overdueResponses[0].createdAt);
          const lastOverdueResponseDate = new Date(overdueResponses[overdueResponses.length - 1].createdAt);

          if (nextOldestOverdueResponseDate === undefined) {
            nextOldestOverdueResponseDate = firstOverdueResponseDate;
          }

          nextNewestOverdueResponseDate = lastOverdueResponseDate;

          contextualLogger.log({
            level: "info",
            message: `Targeting responses from ${firstOverdueResponseDate.toISOString()} to ${lastOverdueResponseDate.toISOString()}.\n\n${overdueResponses.length} new targets have been confirmed.\n\nTotal confirmed casualties: ${nextNumberOfConfirmedOverdueResponses}.`,
          });
        }

        if (lastEvaluatedKey === undefined) {
          return EitherAsyncUtils.right({
            numberOfConfirmedOverdueResponses: nextNumberOfConfirmedOverdueResponses,
            oldestOverdueResponseDate: nextOldestOverdueResponseDate,
            newestOverdueResponseDate: nextNewestOverdueResponseDate,
          });
        } else {
          // Delay next set of actions by 100 ms to avoid DynamoDB API rate limit
          return delayNextAction(100).chain(() =>
            retrieveAndConfirmAllOverdueResponsesWithRecursion(nextNumberOfConfirmedOverdueResponses, nextOldestOverdueResponseDate, nextNewestOverdueResponseDate, lastEvaluatedKey),
          );
        }
      });
  }

  return retrieveAndConfirmAllOverdueResponsesWithRecursion();
}

function retrieveOverdueResponses(
  formId: string,
  ageInDaysAfterResponseConsideredOverdue: number,
  lastEvaluatedKey?: Record<string, NativeAttributeValue>,
): EitherAsync<Error, { overdueResponses: OverdueResponse[]; lastEvaluatedKey?: Record<string, NativeAttributeValue> }> {
  return EitherAsync<Error, QueryCommandOutput>(() =>
    dynamodbClient.send(
      new QueryCommand({
        TableName: process.env.DYNAMODB_VAULT_TABLE_NAME,
        IndexName: process.env.DYNAMODB_VAULT_STATUS_CREATED_AT_V2_INDEX_NAME,
        ExclusiveStartKey: lastEvaluatedKey,
        Limit: 25, // Set to 25 because the confirmation code is limited to 25 updates at a time
        KeyConditionExpression: "FormID = :formId AND #statusCreatedAtKey BETWEEN :lowerBound AND :upperBound",
        ProjectionExpression: "#name,CreatedAt",
        ExpressionAttributeNames: {
          "#statusCreatedAtKey": "Status#CreatedAt",
          "#name": "Name",
        },
        ExpressionAttributeValues: {
          ":formId": formId,
          /**
           * Timestamps must be zero-padded to 13 digits (Unix milliseconds) to ensure
           * lexicographical string ordering matches chronological ordering in DynamoDB.
           * This allows efficient sort key range queries (e.g., finding records older
           * than a given timestamp). Without fixed-width timestamps, string comparisons
           * can produce incorrect results when timestamps have different lengths.
           *
           * IMPORTANT: This approach assumes timestamps remain 13 digits or fewer.
           * Unix millisecond timestamps will reach 14 digits on September 27, 2286.
           * If that happens, the padding width must be increased consistently across
           * all existing and newly created sort keys to preserve chronological ordering.
           */
          ":lowerBound": "Downloaded#0000000000000",
          ":upperBound": `Downloaded#${Date.now() - ageInDaysAfterResponseConsideredOverdue * 24 * 60 * 60 * 1000}`,
        },
      }),
    ),
  )
    .map(({ Items, LastEvaluatedKey }) => ({ overdueResponses: Items?.map((item) => ({ name: item.Name as string, createdAt: item.CreatedAt as number })) ?? [], lastEvaluatedKey: LastEvaluatedKey }))
    .mapLeft((error) => new Error("Failed to retrieve overdue responses", { cause: error }));
}

function confirmOverdueResponses(formId: string, overdueResponses: OverdueResponse[]): EitherAsync<Error, void> {
  if (overdueResponses.length === 0) {
    return EitherAsyncUtils.rightVoid();
  }

  if (overdueResponses.length > 25) {
    return EitherAsyncUtils.left(new Error("This version of the code cannot confirm more than 25 overdue responses at a time (BatchExecuteStatementCommand)"));
  }

  return EitherAsync(() =>
    dynamodbClient.send(
      new BatchExecuteStatementCommand({
        Statements: overdueResponses.map((overdueResponse) => {
          const confirmTimestamp = Date.now();
          const removalDate = confirmTimestamp + 2592000000; // 2592000000 milliseconds = 30 days

          return {
            Statement: `UPDATE "${process.env.DYNAMODB_VAULT_TABLE_NAME}" SET "Status#CreatedAt" = ?, "ConfirmTimestamp" = ?, "RemovalDate" = ? WHERE "FormID" = ? AND "NAME_OR_CONF" = ?`,
            Parameters: [`Confirmed#${overdueResponse.createdAt}`, confirmTimestamp, removalDate, formId, `NAME#${overdueResponse.name}`],
          };
        }),
      }),
    ),
  )
    .chain(({ $metadata: { httpStatusCode }, Responses }) => {
      const errors = Responses?.filter((response) => response.Error !== undefined) ?? [];
      return httpStatusCode === 200 && errors.length === 0
        ? EitherAsyncUtils.rightVoid()
        : EitherAsyncUtils.left(new Error("At least one update statement in the batch did not succeed", { cause: JSON.stringify(errors) }));
    })
    .mapLeft((error) => new Error("Failed to confirm overdue responses", { cause: error }));
}

function delayNextAction(delayInMs: number): EitherAsync<Error, void> {
  return EitherAsync(() => new Promise((resolve) => setTimeout(resolve, delayInMs)));
}

function buildSummaryLogMessage(input: {
  formId: string;
  ageInDaysAfterResponseConsideredOverdue: number;
  numberOfConfirmedOverdueResponses: number;
  oldestOverdueResponseDate?: Date;
  newestOverdueResponseDate?: Date;
}): string {
  if (input.numberOfConfirmedOverdueResponses > 0) {
    return `
The Confirmator has confirmed ${input.numberOfConfirmedOverdueResponses} overdue responses (at least ${input.ageInDaysAfterResponseConsideredOverdue} days old).

Targeted form: ${input.formId}
Targeted responses: from ${input.oldestOverdueResponseDate?.toISOString() ?? "n/a"} to ${input.newestOverdueResponseDate?.toISOString() ?? "n/a"}

Hasta la vista, overdue responses!
`;
  } else {
    return `
The Confirmator has not found any overdue responses (at least ${input.ageInDaysAfterResponseConsideredOverdue} days old).

Targeted form: ${input.formId}

My work here is done. I'll be back!
`;
  }
}
