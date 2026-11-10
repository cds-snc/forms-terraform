import { type NativeAttributeValue, QueryCommand, type QueryCommandOutput, UpdateCommand } from "@aws-sdk/lib-dynamodb";
import { lambdaWithValidatedEventAndContextualLogger } from "common";
import { EitherAsync } from "purify-ts";
import z from "zod";
import { dynamodbClient } from "./lib/awsServicesConnector.ts";

const lambdaEventSchema = z.object({
  formId: z.cuid2(),
});

type OverdueResponsesConfirmatorPayload = z.infer<typeof lambdaEventSchema>;

type LambdaOutput = {
  numberOfOverdueResponsesConfirmed: number;
};

type FormOverdueResponsesResult =
  | { didRetrieveAllResponses: true; responseNames: string[] }
  | { didRetrieveAllResponses: false; responseNames: string[]; lastEvaluatedKey: Record<string, NativeAttributeValue> };

const AGE_AFTER_RESPONSE_CONSIDERED_OVERDUE = 45;

export const handler = lambdaWithValidatedEventAndContextualLogger<OverdueResponsesConfirmatorPayload, LambdaOutput>(lambdaEventSchema, ({ event, contextualLogger }) => {
  return retrieveAndConfirmAllOverdueResponses(event.formId)
    .map(() => ({ numberOfOverdueResponsesConfirmed: 0 }) satisfies LambdaOutput)
    .ifRight(({ numberOfOverdueResponsesConfirmed }) =>
      contextualLogger.log({ level: "info", message: `${numberOfOverdueResponsesConfirmed} overdue responses have been confirmed.\n\nHasta la vista!` }),
    )
    .ifLeft((error) => contextualLogger.log({ level: "error", message: "Something went wrong.\n\nI'll be back!", error }));
});

function retrieveAndConfirmAllOverdueResponses(formId: string): EitherAsync<Error, void> {
  return EitherAsync(async () => {
    let lastEvaluatedKey: Record<string, NativeAttributeValue> | undefined | null = null;

    while (lastEvaluatedKey !== undefined) {
      const test = await retrieveFormOverdueResponses({
        formId,
        minimumAgeToBeConsideredAsOverdue: AGE_AFTER_RESPONSE_CONSIDERED_OVERDUE,
        maximumNumberOfResponsesToBeRetrieved: 50,
        lastEvaluatedKey: lastEvaluatedKey ?? undefined,
      })
        .chain((result) => confirmFormOverdueResponses({ formId: "" }))
        .run();
      // .caseOf({
      //   Left: (error) => {
      //     throw error;
      //   },
      //   Right: (output) => output,
      // });

      lastEvaluatedKey = undefined;
    }
  });
}

function retrieveFormOverdueResponses(input: {
  formId: string;
  minimumAgeToBeConsideredAsOverdue: number;
  maximumNumberOfResponsesToBeRetrieved: number;
  lastEvaluatedKey?: Record<string, NativeAttributeValue>;
}): EitherAsync<Error, FormOverdueResponsesResult> {
  return EitherAsync<Error, QueryCommandOutput>(() =>
    dynamodbClient.send(
      new QueryCommand({
        TableName: process.env.DYNAMODB_VAULT_TABLE_NAME,
        IndexName: process.env.DYNAMODB_VAULT_STATUS_CREATED_AT_V2_INDEX_NAME,
        ExclusiveStartKey: input.lastEvaluatedKey,
        Limit: input.maximumNumberOfResponsesToBeRetrieved,
        KeyConditionExpression: "FormID = :formId AND #statusCreatedAtKey BETWEEN :lowerBound AND :upperBound",
        ProjectionExpression: "#name,CreatedAt",
        ExpressionAttributeNames: {
          "#statusCreatedAtKey": "Status#CreatedAt",
          "#name": "Name",
        },
        ExpressionAttributeValues: {
          ":formId": input.formId,
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
          // ":upperBound": `Downloaded#${Date.now() - input.minimumAgeToBeConsideredAsOverdue * 24 * 60 * 60 * 1000}`,
          ":upperBound": `Downloaded#${Date.now()}`,
        },
      }),
    ),
  )
    .map(({ Items, LastEvaluatedKey }) => {
      console.log(Items);
      if (LastEvaluatedKey === undefined) {
        return { didRetrieveAllResponses: true, responseNames: [] } satisfies FormOverdueResponsesResult;
      } else {
        return { didRetrieveAllResponses: false, responseNames: [], lastEvaluatedKey: LastEvaluatedKey } satisfies FormOverdueResponsesResult;
      }
    })
    .mapLeft((error) => new Error("Failed to retrieve overdue responses", { cause: error }));
}

function confirmFormOverdueResponses(input: { formId: string }): EitherAsync<Error, void> {
  return EitherAsync(() =>
    dynamodbClient.send(
      new UpdateCommand({
        TableName: process.env.DYNAMODB_VAULT_TABLE_NAME,
        Key: {
          // SubmissionID: submissionId,
        },
        UpdateExpression: "SET SendReceipt = :receiptId",
        ExpressionAttributeValues: {
          // ":receiptId": receiptId,
        },
      }),
    ),
  )
    .void()
    .mapLeft((error) => new Error("Failed to confirm overdue responses", { cause: error }));
}
