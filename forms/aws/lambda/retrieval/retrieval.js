const {
  DynamoDBClient,
  DeleteItemCommand,
  QueryCommand,
  BatchWriteItemCommand,
} = require("@aws-sdk/client-dynamodb");

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
      if (formID && !responseID) {
        return await removeAllResponses(formID);
      }
      return await removeResponse(formID, responseID);
    default:
      throw new Error("Action not supported");
  }
};

async function getResponses(formID) {
  const DBParams = {
    TableName: "Vault",
    Limit: 10,
    KeyConditionExpression: "FormID = :form",
    ExpressionAttributeValues: { ":form": { S: formID } },
    ProjectionExpression: "FormID,SubmissionID,FormSubmission",
  };
  return await db.send(new QueryCommand(DBParams));
}
async function getSubmissionIDs(formID) {
  // get the responses in batches of 25
  const DBParams = {
    TableName: "Vault",
    Limit: 25,
    KeyConditionExpression: "FormID = :form",
    ExpressionAttributeValues: { ":form": { S: formID } },
    ProjectionExpression: "SubmissionID",
  };
  return await db.send(new QueryCommand(DBParams));
}

async function removeResponse(formID, submissionID) {
  const DBParams = {
    TableName: "Vault",
    Key: {
      FormID: { S: formID },
      SubmissionID: { S: submissionID },
    },
  };
  //remove data fron DynamoDB
  return await db.send(new DeleteItemCommand(DBParams));
}

async function removeAllResponses(formID) {
  var responsesLeft = true;
  var responseData = [];

  // BatchWriteItem works in batches of 25 max
  while (responsesLeft) {
    let responses = await getSubmissionIDs(formID);
    if (responses.Items.length > 0) {
      // do the deletes
      var DeleteParams = {
        RequestItems: {
          Vault: [],
        },
      };
      // populate the requestItems array with response keys
      for (let i = 0; i < responses.Items.length; i++) {
        DeleteParams.RequestItems.Vault.push({
          DeleteRequest: {
            Key: {
              FormID: { S: responses.Items[i].FormID.S },
              SubmissionID: { S: responses.Items[i].SubmissionID.S },
            },
          },
        });
      }
      // send the request
      // TODO, collect any that fail and retry
      let DBResponse = await db.send(new BatchWriteItemCommand(DeleteParams));
      responseData.push(DBResponse);
    } else {
      responsesLeft = false;
    }
  }
  return responseData;
}
