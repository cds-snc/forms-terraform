import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  BatchWriteCommand,
  QueryCommand,
  QueryCommandOutput,
  ScanCommand,
  ScanCommandOutput,
} from "@aws-sdk/lib-dynamodb";

const DYNAMODB_VAULT_TABLE_NAME = process.env.DYNAMODB_VAULT_TABLE_NAME ?? "";

const dynamodbClient = new DynamoDBClient({
  region: process.env.REGION ?? "ca-central-1",
  ...(process.env.LOCALSTACK === "true" && {
    endpoint: "http://host.docker.internal:4566",
  }),
});

export async function retrieveNewOrDownloadedFormResponsesOver28DaysOld() {
  try {
    let formResponses: { formID: string; createdAt: number }[] = [];
    let lastEvaluatedKey = null;

    while (lastEvaluatedKey !== undefined) {
      const scanResults: ScanCommandOutput = await dynamodbClient.send(
        new ScanCommand({
          TableName: DYNAMODB_VAULT_TABLE_NAME,
          ExclusiveStartKey: lastEvaluatedKey ?? undefined,
          FilterExpression:
            "(begins_with(#statusCreatedAt, :statusNew) OR begins_with(#statusCreatedAt, :statusDownloaded)) AND CreatedAt <= :createdAt",
          ProjectionExpression: "FormID,CreatedAt",
          ExpressionAttributeNames: {
            "#statusCreatedAt": "Status#CreatedAt",
          },
          ExpressionAttributeValues: {
            ":statusNew": "New",
            ":statusDownloaded": "Downloaded",
            ":createdAt": Date.now() - 2419200000, // 2419200000 milliseconds = 28 days
          },
        })
      );

      formResponses = formResponses.concat(
        scanResults.Items?.map((item) => ({
          formID: item.FormID,
          createdAt: item.CreatedAt,
        })) ?? []
      );

      lastEvaluatedKey = scanResults.LastEvaluatedKey;
    }

    return formResponses;
  } catch (error) {
    throw new Error(
      `Failed to retrieve new or downloaded form responses. Reason: ${(error as Error).message}.`
    );
  }
}

export async function deleteOldTestResponses(formID: string) {
  try {
    let accumulatedResponses: string[] = [];
    let lastEvaluatedKey = null;
    while (lastEvaluatedKey !== undefined) {
      const response: QueryCommandOutput = await dynamodbClient.send(
        new QueryCommand({
          TableName: DYNAMODB_VAULT_TABLE_NAME,
          ExclusiveStartKey: lastEvaluatedKey ?? undefined,
          KeyConditionExpression: "FormID = :formID",
          ExpressionAttributeValues: {
            ":formID": formID,
          },
          ProjectionExpression: "NAME_OR_CONF",
        })
      );

      if (response.Items?.length) {
        accumulatedResponses = accumulatedResponses.concat(
          response.Items.map((item) => item.NAME_OR_CONF)
        );
      }
      lastEvaluatedKey = response.LastEvaluatedKey;
    }

    console.log(
      JSON.stringify({
        level: "info",
        msg: `Found ${accumulatedResponses.length} draft responses for form ${formID}.`,
      })
    );

    await deleteDraftFormResponsesFromDynamoDb(formID, accumulatedResponses);
  } catch (e) {
    throw new Error(`Failed to retrieve form responses. Reason: ${(e as Error).message}.`);
  }
}

async function deleteDraftFormResponsesFromDynamoDb(formID: string, formResponses: string[]) {
  try {
    /**
     * The `BatchWriteItemCommand` can only take up to 25 `DeleteRequest` at a time.
     */
    const asyncDeleteRequests = chunks(formResponses, 25).map((request) => {
      return dynamodbClient.send(
        new BatchWriteCommand({
          RequestItems: {
            [DYNAMODB_VAULT_TABLE_NAME]: request.map((entryName) => ({
              DeleteRequest: {
                Key: {
                  FormID: formID,
                  NAME_OR_CONF: entryName,
                },
              },
            })),
          },
        })
      );
    });

    await Promise.all(asyncDeleteRequests);

    console.log(
      JSON.stringify({
        level: "info",
        msg: `Deleted draft responses for form ${formID}.`,
      })
    );
  } catch (error) {
    console.error(
      JSON.stringify({
        level: "error",
        msg: `Failed to delete overdue draft form responses from the Vault for form ${formID}.`,
        error: (error as Error).message,
      })
    );
    throw new Error(
      `Failed to delete overdue draft form responses. Reason: ${(error as Error).message}.`
    );
  }
}

function chunks<T>(arr: T[], size: number): T[][] {
  return Array.from({ length: Math.ceil(arr.length / size) }, (v, i) =>
    arr.slice(i * size, i * size + size)
  );
}
