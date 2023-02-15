const {
  DynamoDBClient,
  GetItemCommand,
  PutItemCommand,
  UpdateItemCommand,
  DeleteItemCommand,
} = require("@aws-sdk/client-dynamodb");
const uuid = require("uuid");

const REGION = process.env.REGION;

async function getSubmission(message) {
  const db = new DynamoDBClient({
    region: REGION,
    ...(process.env.AWS_SAM_LOCAL && { endpoint: "http://host.docker.internal:4566" }),
  });

  const DBParams = {
    TableName: "ReliabilityQueue",
    Key: {
      SubmissionID: { S: message.submissionID },
    },
    ProjectExpression:
      "SubmissionID,FormID,SendReceipt,FormData,FormSubmissionLanguage,CreatedAt,SecurityAttribute,NotifyProcessed",
  };

  return await db.send(new GetItemCommand(DBParams));
}
/**
 * Function that removes the submission from the Reliability Queue.
 * @param {String} submissionID
 * @returns
 */

async function removeSubmission(submissionID) {
  const db = new DynamoDBClient({
    region: REGION,
    endpoint: process.env.AWS_SAM_LOCAL ? "http://host.docker.internal:4566" : undefined,
  });
  const DBParams = {
    TableName: "ReliabilityQueue",
    Key: {
      SubmissionID: { S: submissionID },
    },
  };
  //remove data fron DynamoDB
  return await db.send(new DeleteItemCommand(DBParams));
}

/**
 * Function to update the TTL of a record in the ReliabilityQueue table
 * @param submissionID
 */
async function notifyProcessed(submissionID) {
  const db = new DynamoDBClient({
    region: REGION,
    endpoint: process.env.AWS_SAM_LOCAL ? "http://host.docker.internal:4566" : undefined,
  });

  const expiringTime = (Math.floor(Date.now() / 1000) + 2592000).toString(); // expire after 30 days
  const DBParams = {
    TableName: "ReliabilityQueue",
    Key: {
      SubmissionID: { S: submissionID },
    },
    UpdateExpression: "SET #ttl = :ttl, #processed = :processed",
    ExpressionAttributeNames: {
      "#ttl": "TTL",
      "#processed": "NotifyProcessed",
    },
    ExpressionAttributeValues: {
      ":ttl": {
        N: expiringTime,
      },
      ":processed": {
        BOOL: true,
      },
    },
    ReturnValues: "NONE",
  };

  return await db.send(new UpdateItemCommand(DBParams));
}

async function saveToVault(
  submissionID,
  formResponse,
  formID,
  language,
  createdAt,
  securityAttribute
) {
  const db = new DynamoDBClient({
    region: REGION,
    ...(process.env.AWS_SAM_LOCAL && { endpoint: "http://host.docker.internal:4566" }),
  });

  const formIdentifier = typeof formID === "string" ? formID : formID.toString();
  const formSubmission =
    typeof formResponse === "string" ? formResponse : JSON.stringify(formResponse);

  const submissionDate = new Date(Number(createdAt));
  const name = `${("0" + submissionDate.getDate()).slice(-2)}-${(
    "0" +
    (submissionDate.getMonth() + 1)
  ).slice(-2)}-${submissionID.substring(0, 4)}`;

  const confirmationCode = uuid.v4();

  const SubmissionParams = {
    TableName: "Vault",
    Item: {
      SubmissionID: { S: submissionID },
      FormID: { S: formIdentifier },
      NAME_OR_CONF: { S: `NAME#${name}` },
      FormSubmission: { S: formSubmission },
      FormSubmissionLanguage: { S: language },
      CreatedAt: { N: `${createdAt}` },
      SecurityAttribute: { S: securityAttribute },
      Status: { S: "New" },
      ConfirmationCode: { S: confirmationCode },
      Name: { S: name },
    },
  };
  const ConfirmationParams = {
    TableName: "Vault",
    Item: {
      FormID: { S: formIdentifier },
      NAME_OR_CONF: { S: `CONF#${confirmationCode}` },
      Name: { S: `NAME#${name}` },
    },
  };

  //save data to DynamoDB
  return await Promise.all([
    db.send(new PutItemCommand(SubmissionParams)),
    db.send(new PutItemCommand(ConfirmationParams)),
  ]);
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
    language === "fr" ? question.properties.placeholderFr : question.properties.placeholderEn;
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

module.exports = {
  getSubmission,
  removeSubmission,
  extractFileInputResponses,
  extractFormData,
  saveToVault,
  notifyProcessed,
};
