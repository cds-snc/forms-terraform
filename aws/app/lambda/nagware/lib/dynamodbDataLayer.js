const { DynamoDBClient, QueryCommand } = require("@aws-sdk/client-dynamodb");

const dynamoDb = new DynamoDBClient({
  region: process.env.REGION,
  ...(process.env.AWS_SAM_LOCAL && { endpoint: "http://host.docker.internal:4566" }),
});

async function retrieveFormResponsesOver28DaysOld(status) {
  try {
    let formResponses = [];
    let lastEvaluatedKey = null;

    while (lastEvaluatedKey !== undefined) {
      const queryCommandInput = {
        TableName: process.env.DYNAMODB_VAULT_TABLE_NAME,
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
          response.Items.map(
            (item) => ({
              formID: item.FormID.S,
              createdAt: item.CreatedAt.N,
            })
          )
        );
      }

      lastEvaluatedKey = response.LastEvaluatedKey;
    }

    return formResponses;
  } catch (error) {
    throw new Error(`Failed to retrieve ${status} form responses. Reason: ${error.message}.`);
  }
}

module.exports = {
  retrieveFormResponsesOver28DaysOld,
};
