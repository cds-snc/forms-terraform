import {
  DynamoDBClient,
  QueryCommand,
  BatchWriteItemCommand,
  QueryCommandInput,
} from "@aws-sdk/client-dynamodb";
const dynamoDb = new DynamoDBClient({
  region: process.env.REGION,
  ...(process.env.LOCALSTACK && { endpoint: "http://host.docker.internal:4566" }),
});
const DYNAMODB_VAULT_TABLE_NAME = process.env.DYNAMODB_VAULT_TABLE_NAME ?? "";

export async function retrieveFormResponsesOver28DaysOld(status: string) {
  try {
    let formResponses: { formID: string; createdAt: number }[] = [];
    let lastEvaluatedKey = null;

    while (lastEvaluatedKey !== undefined) {
      const queryCommandInput: QueryCommandInput = {
        TableName: DYNAMODB_VAULT_TABLE_NAME,
        IndexName: "Nagware",
        ExclusiveStartKey: lastEvaluatedKey ?? undefined,
        KeyConditionExpression: "#status = :status AND CreatedAt <= :createdAt",
        ExpressionAttributeNames: {
          "#status": "Status",
        },
        ExpressionAttributeValues: {
          ":status": {
            S: status,
          },
          ":createdAt": {
            N: (Date.now() - 2419200000).toString(), // 2419200000 milliseconds = 28 days
          },
        },
        ProjectionExpression: "FormID,CreatedAt",
      };

      const response = await dynamoDb.send(new QueryCommand(queryCommandInput));

      if (response.Items?.length) {
        formResponses = formResponses.concat(
          response.Items.map((item) => ({
            formID: item.FormID.S ?? "",
            createdAt: item.CreatedAt.N ? Number(item.CreatedAt.N) : 0,
          }))
        );
      }

      lastEvaluatedKey = response.LastEvaluatedKey;
    }

    return formResponses;
  } catch (error) {
    throw new Error(
      `Failed to retrieve ${status} form responses. Reason: ${(error as Error).message}.`
    );
  }
}

export async function deleteOldTestResponses(formID: string) {
  try {
    let accumulatedResponses: string[] = [];
    let lastEvaluatedKey = null;
    while (lastEvaluatedKey !== undefined) {
      const queryCommandInput: QueryCommandInput = {
        TableName: DYNAMODB_VAULT_TABLE_NAME,
        ExclusiveStartKey: lastEvaluatedKey ?? undefined,
        KeyConditionExpression: "FormID = :formID",
        ExpressionAttributeValues: {
          ":formID": {
            S: formID,
          },
        },
        ProjectionExpression: "NAME_OR_CONF",
      };
      const response = await dynamoDb.send(new QueryCommand(queryCommandInput));

      if (response.Items?.length) {
        accumulatedResponses = accumulatedResponses.concat(
          response.Items.map((item) => item.NAME_OR_CONF.S ?? "")
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
  const chunks = (arr: any[], size: number) =>
    Array.from({ length: Math.ceil(arr.length / size) }, (v, i) =>
      arr.slice(i * size, i * size + size)
    );

  try {
    /**
     * The `BatchWriteItemCommand` can only take up to 25 `DeleteRequest` at a time.
     */
    const asyncDeleteRequests = chunks(formResponses, 25).map((request) => {
      return dynamoDb.send(
        new BatchWriteItemCommand({
          RequestItems: {
            [DYNAMODB_VAULT_TABLE_NAME]: request.map((entryName) => ({
              DeleteRequest: {
                Key: {
                  FormID: {
                    S: formID,
                  },
                  NAME_OR_CONF: {
                    S: entryName,
                  },
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
