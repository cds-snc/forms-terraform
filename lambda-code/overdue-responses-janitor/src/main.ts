import { QueryCommand } from "@aws-sdk/lib-dynamodb";
import { EitherAsyncUtils, lambdaWithValidatedEventAndContextualLogger } from "common";
import z from "zod";
import { dynamodbClient } from "./lib/awsServicesConnector.ts";

type LambdaOutput = {
  numberOfOverdueResponsesConfirmed: number;
};

const lambdaEventSchema = z.object({
  formId: z.cuid2(),
});

export type OverdueResponsesJanitorPayload = z.infer<typeof lambdaEventSchema>;

export const handler = lambdaWithValidatedEventAndContextualLogger<OverdueResponsesJanitorPayload, LambdaOutput>(lambdaEventSchema, ({ event, contextualLogger }) => {
  return EitherAsyncUtils.right({ numberOfOverdueResponsesConfirmed: 2 } satisfies LambdaOutput);
});

function test(): void {
  const test = dynamodbClient.send(
    new QueryCommand({
      TableName: process.env.DYNAMODB_VAULT_TABLE_NAME,
      IndexName: "StatusCreatedAt_v2",
      // Limit: 50,
      // ExclusiveStartKey: lastEvaluatedKey,
      // ScanIndexForward: true, // Querying from oldest to newest
      KeyConditionExpression: "FormID = :formId AND #statusCreatedAtKey BETWEEN :lowerLimit AND somethingelse :upperLimit",
      // FilterExpression: "attribute_not_exists(NotifyProcessed)", // Ignore submissions that will be delivered through GC Notify. They will be automatically deleted after 30 days.
      ExpressionAttributeNames: {
        "#statusCreatedAtKey": "Status#CreatedAt",
      },
      ExpressionAttributeValues: {
        ":formId": "formID",
        ":lowerLimit": "Downloaded#1",
        ":upperLimit": "Downloaded#2",
      },
    }),
  );
}
