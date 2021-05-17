const {
  DynamoDBClient,
  GetItemCommand,
  DeleteItemCommand,
  ScanCommand,
} = require("@aws-sdk/client-dynamodb");

const REGION = process.env.REGION;
const db = new DynamoDBClient({ region: REGION });

exports.handler = async function (event) {
  const action = event.action;
  const formID = event.formID;
  const responseID = event.responseID ?? null;

  switch (action) {
    case "GET":
      return await getResponses(formID);
    case "DELETE":
      break;
    default:
      throw new Error("Action not supported");
  }

  return { statusCode: 202 };
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
