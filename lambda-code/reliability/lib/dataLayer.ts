import { DynamoDBClient, TransactionCanceledException } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  GetCommand,
  UpdateCommand,
  DeleteCommand,
  TransactWriteCommand,
} from "@aws-sdk/lib-dynamodb";
import { v4 } from "uuid";
import { FormElement, FormSubmission, Responses, Response } from "./types.js";

const awsProperties = {
  region: process.env.REGION ?? "ca-central-1",
  ...(process.env.LOCALSTACK === "true" && {
    endpoint: "http://host.docker.internal:4566",
  }),
};

const db = DynamoDBDocumentClient.from(new DynamoDBClient(awsProperties));

export async function getSubmission(message: Record<string, unknown>) {
  const DBParams = {
    TableName: "ReliabilityQueue",
    Key: {
      SubmissionID: message.submissionID,
    },
    ProjectExpression:
      "SubmissionID,FormID,SendReceipt,FormData,FormSubmissionLanguage,CreatedAt,SecurityAttribute,NotifyProcessed",
  };

  return await db.send(new GetCommand(DBParams));
}
/**
 * Function that removes the submission from the Reliability Queue.
 * @param {String} submissionID
 * @returns
 */

export async function removeSubmission(submissionID: string) {
  try {
    const DBParams = {
      TableName: "ReliabilityQueue",
      Key: {
        SubmissionID: submissionID,
      },
    };

    return await db.send(new DeleteCommand(DBParams));
  } catch (error) {
    console.error(JSON.stringify(error));
    throw new Error(`Error removing submission ${submissionID} from ReliabilityQueue table`);
  }
}

/**
 * Function to update the TTL of a record in the ReliabilityQueue table
 * @param submissionID
 */
export async function notifyProcessed(submissionID: string) {
  try {
    const expiringTime = Math.floor(Date.now() / 1000) + 2592000; // expire after 30 days
    const DBParams = {
      TableName: "ReliabilityQueue",
      Key: {
        SubmissionID: submissionID,
      },
      UpdateExpression: "SET #ttl = :ttl, #processed = :processed",
      ExpressionAttributeNames: {
        "#ttl": "TTL",
        "#processed": "NotifyProcessed",
      },
      ExpressionAttributeValues: {
        ":ttl": expiringTime,
        ":processed": true,
      },
      ReturnValues: "NONE" as const,
    };

    return await db.send(new UpdateCommand(DBParams));
  } catch (error) {
    console.error(JSON.stringify(error));
    throw new Error(`Error updating Notify TTL for submission ${submissionID}`);
  }
}

export async function saveToVault(
  submissionID: string,
  formResponse: Responses,
  formID: string,
  language: string,
  createdAt: string,
  securityAttribute: string,
  formSubmissionHash: string
) {
  const formSubmission = JSON.stringify(formResponse);

  const confirmationCode = v4();
  const submissionDate = new Date(Number(createdAt));

  let duplicateFound = false;
  let writeSucessfull = false;

  while (!writeSucessfull) {
    try {
      const name = `${("0" + submissionDate.getDate()).slice(-2)}-${(
        "0" +
        (submissionDate.getMonth() + 1)
      ).slice(-2)}-${
        duplicateFound
          ? Math.floor(1000 + Math.random() * 9000).toString()
          : submissionID.substring(0, 4)
      }`;

      const PutSubmission = {
        Put: {
          TableName: "Vault",
          ConditionExpression: "attribute_not_exists(FormID)",
          Item: {
            SubmissionID: submissionID,
            FormID: formID,
            NAME_OR_CONF: `NAME#${name}`,
            FormSubmission: formSubmission,
            FormSubmissionLanguage: language,
            CreatedAt: Number(createdAt),
            SecurityAttribute: securityAttribute,
            Status: "New",
            "Status#CreatedAt": `NEW#${Number(createdAt)}`,
            ConfirmationCode: confirmationCode,
            Name: name,
            FormSubmissionHash: formSubmissionHash,
          },
        },
      };

      const PutConfirmation = {
        Put: {
          TableName: "Vault",
          Item: {
            FormID: formID,
            NAME_OR_CONF: `CONF#${confirmationCode}`,
            Name: name,
            ConfirmationCode: confirmationCode,
          },
        },
      };

      await db.send(
        new TransactWriteCommand({
          TransactItems: [PutSubmission, PutConfirmation],
        })
      );

      writeSucessfull = true;
    } catch (error) {
      if (error instanceof TransactionCanceledException) {
        error.CancellationReasons?.forEach((reason) => {
          if (reason.Code === "ConditionalCheckFailed") {
            duplicateFound = true;
            console.info(
              JSON.stringify({
                level: "info",
                msg: `Duplicate Submission Name Found - recreating with randomized name`,
              })
            );
          }
        });
      } else {
        // Not a duplication error, something else has gone wrong
        console.error(JSON.stringify(error));
        throw new Error(
          `Error saving submission to vault for submission ID ${submissionID} / FormID: ${formID}`
        );
      }
    }
  }
}

// Email submission data manipulation

export function extractFileInputResponses(submission: FormSubmission) {
  const fileInputElements: string[] = submission.form.elements
    .filter((element) => element.type === "fileInput")
    .map((element) => submission.responses[element.id] as string)
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
        element.properties.subElements?.reduce(
          (acc: string[], current: FormElement, currentIndex: number) => {
            if (current.type === "fileInput") {
              const response = submission.responses[element.id];
              const subElementFiles: string[] = [];
              if (Array.isArray(response)) {
                response.forEach((element) => {
                  // @ts-expect-error
                  const answer = element[currentIndex];
                  if (
                    answer &&
                    answer !== "" &&
                    typeof answer === "string" &&
                    answer.startsWith("form_attachments")
                  ) {
                    subElementFiles.push(answer);
                  }
                });
                return [...acc, ...subElementFiles];
              }

              return [...acc];
            } else {
              return acc;
            }
          },
          []
        ) ?? []
      );
    })
    .flat();

  return [...fileInputElements, ...dynamicRowElementsIncludingFileInputComponents];
}

export function extractFormData(submission: FormSubmission, language: string) {
  const formResponses = submission.responses;
  const formOrigin = submission.form;
  const dataCollector: string[] = [];
  formOrigin.layout.map((qID) => {
    const question = formOrigin.elements.find((element) => element.id === qID);
    if (question) {
      handleType(question, formResponses[question.id], language, dataCollector);
    }
  });
  return dataCollector;
}

function handleType(
  question: FormElement,
  response: Response,
  language: string,
  collector: string[]
) {
  const qTitle = language === "fr" ? question.properties.titleFr : question.properties.titleEn;
  const qRowLabel =
    language === "fr" ? question.properties.placeholderFr : question.properties.placeholderEn;
  switch (question.type) {
    case "textField":
    case "textArea":
    case "dropdown":
    case "radio":
    case "combobox":
      handleTextResponse(qTitle, response, collector);
      break;
    case "checkbox":
      handleArrayResponse(qTitle, response, collector);
      break;
    case "dynamicRow":
      if (!question.properties.subElements) throw new Error("Dynamic Row must have sub elements");
      handleDynamicForm(qTitle, qRowLabel, response, question.properties.subElements, collector);
      break;
    case "fileInput":
      handleFileInputResponse(qTitle, response, collector);
      break;
    default:
      // Do not try to handle form elements like richText that do not have responses
      break;
  }
}

function handleDynamicForm(
  title: string,
  rowLabel = "Item",
  response: Response,
  question: FormElement[],
  collector: string[]
) {
  if (!Array.isArray(response)) throw new Error("Dynamic Row responses must be in an array");
  const responseCollector = response.map((row, rIndex: number) => {
    const rowCollector: string[] = [];
    question.map((qItem, qIndex) => {
      // Add i18n here eventually?
      const qTitle = qItem.properties.titleEn;
      switch (qItem.type) {
        case "textField":
        case "textArea":
        case "dropdown":
        case "radio":
        case "combobox":
          handleTextResponse(qTitle, (row as Record<string, Response>)[qIndex], rowCollector);
          break;
        case "fileInput":
          handleFileInputResponse(qTitle, (row as Record<string, Response>)[qIndex], rowCollector);
          break;
        case "checkbox":
          handleArrayResponse(qTitle, (row as Record<string, Response>)[qIndex], rowCollector);
          break;
        default:
          // Do not try to handle form elements like richText that do not have responses
          break;
      }
    });
    rowCollector.unshift(`${String.fromCharCode(13)}***${rowLabel} ${rIndex + 1}***`);
    return rowCollector.join(String.fromCharCode(13));
  });
  responseCollector.unshift(`**${title}**`);
  collector.push(responseCollector.join(String.fromCharCode(13)));
}

function handleArrayResponse(title: string, response: Response, collector: string[]) {
  if (!Array.isArray(response)) throw new Error("Checkbox responses must be in an array");
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

function handleTextResponse(title: string, response: Response, collector: string[]) {
  if (response !== undefined && response !== null && response !== "") {
    collector.push(`**${title}**${String.fromCharCode(13)}${response}`);
    return;
  }

  collector.push(`**${title}**${String.fromCharCode(13)}No Response`);
}

function handleFileInputResponse(title: string, response: Response, collector: string[]) {
  if (response !== undefined && response !== null && response !== "") {
    const fileName = (response as string).split("/").pop();
    collector.push(`**${title}**${String.fromCharCode(13)}${fileName}`);
    return;
  }

  collector.push(`**${title}**${String.fromCharCode(13)}No Response`);
}
