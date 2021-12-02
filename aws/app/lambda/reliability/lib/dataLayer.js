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
    ProjectExpression: "SubmissionID,FormID,SendReceipt,FormData,FormSubmissionLanguage",
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

function extractFileInputResponses(submission) {
  const fileInputElements = submission.form.elements
    .filter((element) => element.type === "fileInput")
    .map((element) => submission.responses[element.id])
    .filter((response) => response !== "");

  const dynamicRowElementsIncludingFileInputComponents = submission.form.elements
    // Filter down to only dynamicRow elements
    .filter((element) => element.type === "dynamicRow")
    // Filter down to only dynamicRow elements that contain fileInputs
    .filter(
      (element) =>
        element.properties.subElements?.filter((subElement) => subElement.type === "fileInput") ??
        false
    )
    .map((element) => {
      return (
        element.properties.subElements
          // Accumulates file input paths contained in dynamic row responses
          .reduce((acc, current, currentIndex) => {
            if (current.type === "fileInput") {
              const values = [];
              const responses = submission.responses[element.id];
              responses.forEach((response) => {
                const fileInputPath = response[currentIndex];
                if (fileInputPath !== "") values.push(fileInputPath);
              });
              return [...acc, ...values];
            } else {
              return acc;
            }
          }, []) ?? []
      );
    })
    .flat();

  return [...fileInputElements, ...dynamicRowElementsIncludingFileInputComponents];
}

function extractFormData(submission, language) {
  const formResponses = submission.responses;
  const formOrigin = submission.form;
  const dataCollector = [];
  formOrigin.layout.map((qID) => {
    const question = formOrigin.elements.find((element) => element.id === qID);
    if (question) {
      handleType(question, formResponses[question.id], language, dataCollector);
    }
  });
  return dataCollector;
}

function handleType(question, response, language, collector) {
  const qTitle = language === "fr" ? question.properties.titleFr : question.properties.titleEn;
  const qRowLabel =
    language === "fr" ? question.properties.placeholderFr : question.properties.placeholderFr;
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
      handleDynamicForm(qTitle, qRowLabel, response, question.properties.subElements, collector);
      break;
    case "fileInput":
      handleFileInputResponse(qTitle, response, collector);
      break;
  }
}

function handleDynamicForm(title, rowLabel = "Item", response, question, collector) {
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
        case "fileInput":
          handleFileInputResponse(qTitle, row[qIndex], rowCollector);
          break;
        case "checkbox":
          handleArrayResponse(qTitle, row[qIndex], rowCollector);
          break;
        default:
          break;
      }
    });
    rowCollector.unshift(`${String.fromCharCode(13)}***${rowLabel} ${rIndex + 1}***`);
    return rowCollector.join(String.fromCharCode(13));
  });
  responseCollector.unshift(`**${title}**`);
  collector.push(responseCollector.join(String.fromCharCode(13)));
}

function handleArrayResponse(title, response, collector) {
  if (response.length) {
    if (Array.isArray(response)) {
      const responses = response
        .map((item) => {
          return `-  ${item}`;
        })
        .join(String.fromCharCode(13));
      collector.push(`**${title}**${String.fromCharCode(13)}${responses}`);
      return;
    } else {
      handleTextResponse(title, response, collector);
      return;
    }
  }
  collector.push(`**${title}**${String.fromCharCode(13)}No response`);
}

function handleTextResponse(title, response, collector) {
  if (response !== undefined && response !== null && response !== "") {
    collector.push(`**${title}**${String.fromCharCode(13)}${response}`);
    return;
  }

  collector.push(`**${title}**${String.fromCharCode(13)}No Response`);
}

function handleFileInputResponse(title, response, collector) {
  if (response !== undefined && response !== null && response !== "") {
    const fileName = response.split("/").pop();
    collector.push(`**${title}**${String.fromCharCode(13)}${fileName}`);
    return;
  }

  collector.push(`**${title}**${String.fromCharCode(13)}No Response`);
}

function formatError(err) {
  return typeof err === "object" ? JSON.stringify(err) : err;
}

module.exports = {
  getSubmission,
  removeSubmission,
  extractFileInputResponses,
  extractFormData,
  saveToVault,
  formatError,
};
