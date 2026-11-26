import { BatchExecuteStatementCommand, type NativeAttributeValue, QueryCommand, type QueryCommandOutput } from "@aws-sdk/lib-dynamodb";
import { EitherAsyncUtils } from "common";
import { EitherAsync } from "purify-ts";
import { dynamodbClient } from "./awsServicesConnector.ts";

export type OverdueResponse = {
  name: string;
  createdAt: number;
};

export function retrieveNextBatchOfOverdueResponses(
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

export function confirmOverdueResponses(formId: string, overdueResponses: OverdueResponse[]): EitherAsync<Error, void> {
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
