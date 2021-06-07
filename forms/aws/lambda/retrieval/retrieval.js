const { DynamoDBClient, DeleteItemCommand, ScanCommand, BatchWriteItemCommand } = require("@aws-sdk/client-dynamodb");

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
      if (formID) {
        return await removeAllResponses(formID);
      }
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
async function getSubmissionIDs(formID) {
  // get the responses in batches of 25
  const DBParams = {
    TableName: "Vault",
    Limit: 25,
    FilterExpression: "FormID = :form",
    ExpressionAttributeValues: { ":form": { S: formID } },
    ProjectionExpression: "SubmissionID",
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

async function removeAllResponses(formID) {
  var responsesLeft = true;
  var responseData = [];

  // BatchWriteItem works in batches of 25 max
  while (responsesLeft) {
    let responses = await getSubmissionIDs(formID);
    if (responses.Items) {
      // do the deletes
      var DeleteParams = {
        RequestItems: {
          Vault: []
        }
      };
      // populate the requestItems array with response keys
      for (let i=0; i < responses.Items.length; i++) {
        DeleteParams.RequestItems.Vault.push({
          DeleteRequest: {
            Key: {
              SubmissionID: {S: responses.Items[i].SubmissionID.S}
            }
          }
        });
      }
      // send the request
      // TODO, collect any that fail and retry
      responseData.push(await db.send(new BatchWriteItemCommand(DeleteParams)));
    } else {
      responsesLeft = false;
      return (responseData) ? responseData : responses;
    }
  }
}
