import { DynamoDBClient, TransactionCanceledException } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  GetCommand,
  UpdateCommand,
  DeleteCommand,
  TransactWriteCommand,
} from "@aws-sdk/lib-dynamodb";
import { v4 } from "uuid";
import {
  FormElement,
  FormSubmission,
  Responses,
  Response,
  DateFormat,
  DateObject,
  AddressElements,
  AddressCompleteProps,
} from "./types.js";
import { getFormattedDateFromObject } from "./utils.js";

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
            "Status#CreatedAt": `New#${Number(createdAt)}`,
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
            CreatedAt: Number(createdAt),
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
      handleDynamicForm(qTitle, qRowLabel, response, question.properties.subElements, collector, language);
      break;
    case "fileInput":
      handleFileInputResponse(qTitle, response, collector);
      break;
    case "formattedDate":
      handleFormattedDateResponse(
        qTitle,
        response,
        question.properties.dateFormat as DateFormat,
        collector
      );
      break;
    case "addressComplete":
      handleAddressCompleteResponse(qTitle, response, collector, language, question.properties.addressComponents);
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
  collector: string[],
  language: string
) {
  if (response === undefined || response === null || Array.isArray(response) === false) return;

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
        case "formattedDate":
          handleFormattedDateResponse(
            qTitle,
            (row as Record<string, Response>)[qIndex],
            qItem.properties.dateFormat as DateFormat,
            rowCollector
          );
          break;
        case "addressComplete":
          handleAddressCompleteResponse(
            qTitle,
            (row as Record<string, Response>)[qIndex],
            rowCollector,
            language,
            qItem.properties.addressComponents
          );
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
  if (Array.isArray(response) && response.length > 0) {
    const responses = response.map((item) => `-  ${item}`).join(String.fromCharCode(13));
    collector.push(`**${title}**${String.fromCharCode(13)}${responses}`);
    return;
  }

  // Note the below dash is an em_dash (longer dash). This is a work around for a lone dash being
  // stripped out in an email. Same fore similar cases below.
  collector.push(`**${title}**${String.fromCharCode(13)}—`);
}

function handleTextResponse(title: string, response: Response, collector: string[]) {
  if (response !== undefined && response !== null && response !== "") {
    collector.push(`**${title}**${String.fromCharCode(13)}${response}`);
    return;
  }

  collector.push(`**${title}**${String.fromCharCode(13)}—`); 
}

function handleFileInputResponse(title: string, response: Response, collector: string[]) {
  if (response !== undefined && response !== null && response !== "") {
    const fileName = (response as string).split("/").pop();
    collector.push(`**${title}**${String.fromCharCode(13)}${fileName}`);
    return;
  }

  collector.push(`**${title}**${String.fromCharCode(13)}—`);
}

function handleFormattedDateResponse(
  title: string,
  response: Response,
  dateFormat: DateFormat,
  collector: string[]
) {
  if (response !== undefined && response !== null && response !== "") {
    collector.push(
      `**${title}**${String.fromCharCode(13)}${getFormattedDateFromObject(
        dateFormat,
        JSON.parse(String(response))
      )}`
    );
    return;
  }

  collector.push(`**${title}**${String.fromCharCode(13)}—`);
}

function handleAddressCompleteResponse(title: string, response: Response, collector: string[], language: string, adddressComponents?: AddressCompleteProps) {
  if (response !== undefined && response !== null && response !== "") {
    const address = JSON.parse(response as string) as AddressElements;
    if (adddressComponents?.splitAddress) {
      collector.push(`**${title} - ${language === "fr" ? "Adresse municipale" : "Street Address"}**${String.fromCharCode(13)}${address.streetAddress}`);
      collector.push(`**${title} - ${language === "fr" ? "City or Town" : "Ville ou communauté"} **${String.fromCharCode(13)}${address.city}`);
      collector.push(`**${title} - ${language === "fr" ? "Province, territoire ou état " : "Province, territory or state"}**${String.fromCharCode(13)}${address.province}`);
      collector.push(`**${title} - ${language === "fr" ? "Code postal ou zip" : "Postal Code or zip"}**${String.fromCharCode(13)}${address.postalCode}`);
      if (!adddressComponents.canadianOnly) {
        collector.push(`**${title} - ${language === "fr" ? "Pays" : "Country"}**${String.fromCharCode(13)}${address.country}`);
      }
    } else {
      const addressString = `${address.streetAddress}, ${address.city}, ${address.province}, ${address.postalCode}`;
      if (!adddressComponents?.canadianOnly) {
        addressString.concat(`, ${address.country}`);
      }
      collector.push(`**${title}**${String.fromCharCode(13)}${addressString}`);
    }
    
    return;
  }

  collector.push(`**${title}**${String.fromCharCode(13)}—`);
}
