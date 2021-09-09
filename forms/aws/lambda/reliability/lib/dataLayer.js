const {
  DynamoDBClient,
  GetItemCommand,
  DeleteItemCommand,
  PutItemCommand,
} = require("@aws-sdk/client-dynamodb");

const REGION = process.env.REGION;

async function getSubmission(message) {
  const db = new DynamoDBClient({ region: REGION });
  const DBParams = {
    TableName: "ReliabilityQueue",
    Key: {
      SubmissionID: { S: message.submissionID },
    },
    ProjectExpression: "SubmissionID,FormID,SendReceipt,FormData",
  };
  //save data to DynamoDB
  return await db.send(new GetItemCommand(DBParams));
}

async function removeSubmission(message) {
  const db = new DynamoDBClient({ region: REGION });
  const DBParams = {
    TableName: "ReliabilityQueue",
    Key: {
      SubmissionID: { S: message.submissionID },
    },
  };
  //remove data fron DynamoDB
  return await db.send(new DeleteItemCommand(DBParams));
}

async function saveToVault(submissionID, formResponse, formID) {
  const db = new DynamoDBClient({ region: REGION });
  const formSubmission =
    typeof formResponse === "string" ? formResponse : JSON.stringify(formResponse);

  const formIdentifier = typeof formID === "string" ? formID : formID.toString();

  const DBParams = {
    TableName: "Vault",
    Item: {
      SubmissionID: { S: submissionID },
      FormID: { S: formIdentifier },
      FormSubmission: { S: formSubmission },
    },
  };
  //save data to DynamoDB
  return await db.send(new PutItemCommand(DBParams));
}

// Email submission data manipulation

function extractFormData(submission) {
  const formResponses = submission.responses;
  const formOrigin = submission.form;
  const dataCollector = [];
  formOrigin.layout.map((qID) => {
    const question = formOrigin.elements.find((element) => element.id === qID);
    if (question) {
      handleType(question, formResponses[question.id], dataCollector);
    }
  });
  return dataCollector;
}

function handleType(question, response, collector) {
  // Add i18n here later on?
  // Do we detect lang submission or output with mixed lang?
  const qTitle = question.properties.titleEn;
  switch (question.type) {
    case "textField":
    case "textArea":
    case "dropdown":
    case "radio":
      handleTextResponse(qTitle, response, collector);
      break;

    case "checkbox":
      handleArrayResponse(qTitle, response, collector);
      break;
    case "dynamicRow":
      handleDynamicForm(qTitle, response, question.properties.subElements, collector);
      break;
    case "fileInput":
      handleTextResponse(qTitle, response, collector);
      break;
  }
}

function handleDynamicForm(title, response, question, collector) {
  const responseCollector = response.map((row, rIndex) => {
    const rowCollector = [];
    question.map((qItem, qIndex) => {
      // Add i18n here eventually?
      const qTitle = qItem.properties.titleEn;
      switch (qItem.type) {
        case "textField":
        case "textArea":
        case "dropdown":
        case "radio":
          handleTextResponse(qTitle, row[qIndex], rowCollector);
          break;

        case "checkbox":
          handleArrayResponse(qTitle, row[qIndex], rowCollector);
          break;
      }
    });
    rowCollector.unshift(`Item ${rIndex + 1}`);
    return rowCollector.join(String.fromCharCode(13));
  });
  responseCollector.unshift(title);
  collector.push(responseCollector.join(String.fromCharCode(13)));
}

function handleArrayResponse(title, response, collector) {
  if (response.length) {
    if (Array.isArray(response)) {
      const responses = response
        .map((item) => {
          return `- ${item}`;
        })
        .join(String.fromCharCode(13));
      collector.push(`${title}${String.fromCharCode(13)}${responses}`);
      return;
    } else {
      handleTextResponse(title, response, collector);
      return;
    }
  }
  collector.push(`${title}${String.fromCharCode(13)}- No response`);
}

function handleTextResponse(title, response, collector) {
  if (response !== undefined && response !== null && response !== "") {
    collector.push(`${title}${String.fromCharCode(13)}-${response}`);
    return;
  }

  collector.push(`${title}${String.fromCharCode(13)}- No Response`);
}

function formatError(err) {
  return typeof err === "object" ? JSON.stringify(err) : err;
}

module.exports = {
  getSubmission,
  removeSubmission,
  extractFormData,
  saveToVault,
  formatError,
};
