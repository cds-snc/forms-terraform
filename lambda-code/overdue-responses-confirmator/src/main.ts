import { BatchExecuteStatementCommand, type NativeAttributeValue, QueryCommand, type QueryCommandOutput } from "@aws-sdk/lib-dynamodb";
import { EitherAsyncUtils, lambdaWithValidatedEventAndContextualLogger } from "common";
import { EitherAsync } from "purify-ts";
import z from "zod";
import { dynamodbClient } from "./lib/awsServicesConnector.ts";

const lambdaEventSchema = z.object({
  formId: z.cuid2(),
});

type OverdueResponsesConfirmatorPayload = z.infer<typeof lambdaEventSchema>;

const AGE_AFTER_RESPONSE_CONSIDERED_OVERDUE = 45;

export const handler = lambdaWithValidatedEventAndContextualLogger<OverdueResponsesConfirmatorPayload, void>(lambdaEventSchema, ({ event, contextualLogger }) => {
  return retrieveAndConfirmAllOverdueResponses(event.formId)
    .ifRight(({ numberOfOverdueResponsesConfirmed }) =>
      contextualLogger.log({ level: "info", message: `${numberOfOverdueResponsesConfirmed} overdue responses have been confirmed.\n\nHasta la vista!` }),
    )
    .void()
    .ifLeft((error) => contextualLogger.log({ level: "error", message: "Something went wrong.\n\nI'll be back!", error }));
});

function retrieveAndConfirmAllOverdueResponses(formId: string): EitherAsync<Error, { numberOfOverdueResponsesConfirmed: number }> {
  return EitherAsync(async ({ throwE }) => {
    let numberOfOverdueResponsesConfirmed = 0;
    let lastEvaluatedKey: Record<string, NativeAttributeValue> | undefined | null = null;

    while (lastEvaluatedKey !== undefined) {
      await retrieveFormOverdueResponses(formId, lastEvaluatedKey ?? undefined)
        .chain(EitherAsyncUtils.ifRightAsync(({ responseNames }) => (responseNames.length > 0 ? confirmFormOverdueResponses(formId, responseNames) : EitherAsyncUtils.rightVoid())))
        .caseOf({
          Right: ({ responseNames, lastEvaluatedKey: nextLastEvaluatedKey }) => {
            numberOfOverdueResponsesConfirmed += responseNames.length;
            lastEvaluatedKey = nextLastEvaluatedKey;
          },
          Left: (error) => throwE(error),
        });
    }

    return { numberOfOverdueResponsesConfirmed };
  });
}

function retrieveFormOverdueResponses(
  formId: string,
  lastEvaluatedKey?: Record<string, NativeAttributeValue>,
): EitherAsync<Error, { responseNames: string[]; lastEvaluatedKey?: Record<string, NativeAttributeValue> }> {
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
          // ":upperBound": `Downloaded#${Date.now() - AGE_AFTER_RESPONSE_CONSIDERED_OVERDUE * 24 * 60 * 60 * 1000}`,
          ":upperBound": `Downloaded#${Date.now()}`,
        },
      }),
    ),
  )
    .map(({ Items, LastEvaluatedKey }) => ({ responseNames: Items?.map((item) => item.Name as string) ?? [], lastEvaluatedKey: LastEvaluatedKey }))
    .mapLeft((error) => new Error("Failed to retrieve overdue responses", { cause: error }));
}

function confirmFormOverdueResponses(formId: string, responseNames: string[]): EitherAsync<Error, void> {
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
