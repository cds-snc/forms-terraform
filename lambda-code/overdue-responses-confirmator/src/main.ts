import { BatchExecuteStatementCommand, type NativeAttributeValue, QueryCommand, type QueryCommandOutput } from "@aws-sdk/lib-dynamodb";
import { EitherAsyncUtils, lambdaWithValidatedEventAndContextualLogger } from "common";
import { EitherAsync } from "purify-ts";
import z from "zod";
import { dynamodbClient } from "./lib/awsServicesConnector.ts";

const AGE_IN_DAYS_AFTER_RESPONSE_CONSIDERED_OVERDUE = 45;

const lambdaEventSchema = z.object({
  formId: z.cuid2(),
});

type OverdueResponsesConfirmatorPayload = z.infer<typeof lambdaEventSchema>;

type OverdueResponse = {
  name: string;
  createdAt: number;
};

export const handler = lambdaWithValidatedEventAndContextualLogger<OverdueResponsesConfirmatorPayload, void>(lambdaEventSchema, ({ event, contextualLogger }) => {
  return retrieveAndConfirmAllOverdueResponses(event.formId)
    .ifRight(({ numberOfConfirmedOverdueResponses, oldestOverdueResponseDate, newestOverdueResponseDate }) =>
      contextualLogger.log({
        level: "info",
        message: `
The Confirmator has confirmed ${numberOfConfirmedOverdueResponses} overdue responses.
        
Target acquisition - Oldest / Newest overdue response:
${oldestOverdueResponseDate?.toISOString() ?? "n/a"} / ${newestOverdueResponseDate?.toISOString() ?? "n/a"}
        
Hasta la vista, overdue responses!
`,
      }),
    )
    .void()
    .ifLeft((error) => contextualLogger.log({ level: "error", message: "No problemo... just a minor system malfunction.\n\nI'll be back!", error }));
});

function retrieveAndConfirmAllOverdueResponses(formId: string): EitherAsync<Error, { numberOfConfirmedOverdueResponses: number; oldestOverdueResponseDate?: Date; newestOverdueResponseDate?: Date }> {
  return EitherAsync(async ({ throwE }) => {
    let lastEvaluatedKey: Record<string, NativeAttributeValue> | undefined | null = null;

    let numberOfConfirmedOverdueResponses = 0;
    let oldestOverdueResponseDate: Date | undefined;
    let newestOverdueResponseDate: Date | undefined;

    while (lastEvaluatedKey !== undefined) {
      await retrieveOverdueResponses(formId, AGE_IN_DAYS_AFTER_RESPONSE_CONSIDERED_OVERDUE, lastEvaluatedKey ?? undefined)
        .chain(
          EitherAsyncUtils.ifRightAsync(({ overdueResponses }) =>
            overdueResponses.length > 0
              ? confirmOverdueResponses(
                  formId,
                  overdueResponses.map((r) => r.name),
                )
              : EitherAsyncUtils.rightVoid(),
          ),
        )
        .caseOf({
          Right: ({ overdueResponses, lastEvaluatedKey: nextLastEvaluatedKey }) => {
            lastEvaluatedKey = nextLastEvaluatedKey;
            numberOfConfirmedOverdueResponses += overdueResponses.length;

            if (oldestOverdueResponseDate === undefined) {
              const firstOverdueResponseCreatedAt = overdueResponses.at(0)?.createdAt;
              oldestOverdueResponseDate = firstOverdueResponseCreatedAt ? new Date(firstOverdueResponseCreatedAt) : undefined;
              newestOverdueResponseDate = firstOverdueResponseCreatedAt ? new Date(firstOverdueResponseCreatedAt) : undefined;
            }

            const lastOverdueResponseCreatedAt = overdueResponses.at(-1)?.createdAt;
            newestOverdueResponseDate = lastOverdueResponseCreatedAt ? new Date(lastOverdueResponseCreatedAt) : undefined;
          },
          Left: (error) => throwE(error),
        });
    }

    return { numberOfConfirmedOverdueResponses, oldestOverdueResponseDate, newestOverdueResponseDate };
  });
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

function confirmOverdueResponses(formId: string, responseNames: string[]): EitherAsync<Error, void> {
  if (responseNames.length > 25) {
    return EitherAsyncUtils.left(new Error("This version of the code cannot confirm more than 25 overdue responses at a time (BatchExecuteStatementCommand)"));
  }

  return EitherAsync(() =>
    dynamodbClient.send(
      new BatchExecuteStatementCommand({
        Statements: responseNames.map((responseName) => ({
          Statement: `UPDATE "${process.env.DYNAMODB_VAULT_TABLE_NAME}" SET WillConfirm = 'confirmed' WHERE "FormID" = '${formId}' AND "NAME_OR_CONF" = 'NAME#${responseName}'`,
        })),
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
