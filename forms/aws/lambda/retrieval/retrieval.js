const { DynamoDBClient, DeleteItemCommand, ScanCommand } = require("@aws-sdk/client-dynamodb");

const REGION = process.env.REGION;
const db = new DynamoDBClient({ region: REGION });

exports.handler = async function (event) {
  const action = event.action;
  const formID = event.formID || null;
  const responseID = event.responseID || null;

  switch (action) {
    case "GET":
      return await getResponses(formID);
    case "DELETE":
      return await removeResponse(responseID);
    default:
      throw new Error("Action not supported");
  }
};

async function getResponses(formID) {
  const DBParams = {
    TableName: "Vault",
    Limit: 10,
    FilterExpression: "FormID = :form",
    ExpressionAttributeValues: { ":form": { S: formID } },
    ProjectionExpression: "SubmissionID,FormID,FormSubmission",
  };
  return await db.send(new ScanCommand(DBParams));
}

async function removeResponse(submissionID) {
  const DBParams = {
    TableName: "Vault",
    Key: {
      SubmissionID: { S: submissionID },
    },
  };
  //remove data fron DynamoDB
  return await db.send(new DeleteItemCommand(DBParams));
}
