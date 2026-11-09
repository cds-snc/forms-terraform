import type { AddressComponents, AddressElements, DateFormat, DateObject, FileInputResponse, FormElement, FormProperties, Response, Responses } from "@gcforms/types";
import json2md from "json2md";

// export type FormSubmission = {
//   form: FormProperties;
//   responses: Responses;
//   deliveryOption: DeliveryOption;
// };
export function buildEmailMarkdownContent(input: {
  emailSubject: string;
  formTemplate: FormProperties;
  submission: { id: string; createdAt: number; language: string; responsesAsJson: string };
}): string {
  const stringifiedData = extractFormData({
    formTemplate: input.formTemplate,
    submission: { language: input.submission.language, responses: JSON.parse(input.submission.responsesAsJson) },
  });

  const mdBody = stringifiedData.map((item) => {
    return { p: item };
  });

  let emailMarkdown = json2md([{ h1: input.emailSubject }, mdBody]);
  const isoCreatedAtString = new Date(input.submission.createdAt).toISOString();

  // Using language attribute tags https://notification.canada.ca/format
  // This is done so screen readers can read in the correct voice
  if (input.submission.language === "fr") {
    emailMarkdown = `[[fr]]\n${emailMarkdown}\nDate de soumission : ${isoCreatedAtString}\nID : ${input.submission.id}\n[[/fr]]`;
  } else {
    emailMarkdown = `[[en]]\n${emailMarkdown}\nSubmission Date: ${isoCreatedAtString}\nID: ${input.submission.id}\n[[/en]]`;
  }

  return emailMarkdown;
}

function extractFormData(input: { formTemplate: FormProperties; submission: { language: string; responses: Responses } }) {
  const dataCollector: string[] = [];
  input.formTemplate.layout.forEach((qId) => {
    const question = input.formTemplate.elements.find((element) => element.id === qId);
    if (question) {
      handleType(question, input.submission.responses[question.id], input.submission.language, dataCollector);
    }
  });
  return dataCollector;
}

function handleType(question: FormElement, response: Response, language: string, collector: string[]) {
  const qTitle = language === "fr" ? question.properties.titleFr : question.properties.titleEn;
  const qRowLabel = language === "fr" ? question.properties.placeholderFr : question.properties.placeholderEn;
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
      handleFileInputResponse(qTitle, response as FileInputResponse, collector);
      break;
    case "formattedDate":
      handleFormattedDateResponse(qTitle, response, question.properties.dateFormat as DateFormat, collector);
      break;
    case "addressComplete":
      handleAddressCompleteResponse(qTitle, response, collector, language, question.properties.addressComponents);
      break;
    default:
      // Do not try to handle form elements like richText that do not have responses
      break;
  }
}

function handleDynamicForm(title: string, rowLabel = "Item", response: Response, question: FormElement[], collector: string[], language: string) {
  if (response === undefined || response === null || Array.isArray(response) === false) return;

  const responseCollector = response.map((row, rIndex: number) => {
    const rowCollector: string[] = [];
    question.forEach((qItem, qIndex) => {
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
          handleFileInputResponse(qTitle, (row as Record<string, Response>)[qIndex] as FileInputResponse, rowCollector);
          break;
        case "checkbox":
          handleArrayResponse(qTitle, (row as Record<string, Response>)[qIndex], rowCollector);
          break;
        case "formattedDate":
          handleFormattedDateResponse(qTitle, (row as Record<string, Response>)[qIndex], qItem.properties.dateFormat as DateFormat, rowCollector);
          break;
        case "addressComplete":
          handleAddressCompleteResponse(qTitle, (row as Record<string, Response>)[qIndex], rowCollector, language, qItem.properties.addressComponents);
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

function escapeMarkdownLinks(text: string): string {
  return text.replace(/\[([^\]]*)\]\(([^)]*)\)/g, "\\[$1\\]($2)");
}

function handleTextResponse(title: string, response: Response, collector: string[]) {
  if (response !== undefined && response !== null && response !== "") {
    collector.push(`**${title}**${String.fromCharCode(13)}${escapeMarkdownLinks(String(response))}`);
    return;
  }

  collector.push(`**${title}**${String.fromCharCode(13)}—`);
}

function handleFileInputResponse(title: string, response: FileInputResponse, collector: string[]) {
  if (response !== undefined && response !== null) {
    collector.push(`**${title}**${String.fromCharCode(13)}${response.name}`);
    return;
  }

  collector.push(`**${title}**${String.fromCharCode(13)}—`);
}

function handleFormattedDateResponse(title: string, response: Response, dateFormat: DateFormat, collector: string[]) {
  if (response !== undefined && response !== null && response !== "") {
    collector.push(`**${title}**${String.fromCharCode(13)}${getFormattedDateFromObject(dateFormat, response)}`);
    return;
  }

  collector.push(`**${title}**${String.fromCharCode(13)}—`);
}

function handleAddressCompleteResponse(title: string, response: Response, collector: string[], language: string, adddressComponents?: AddressComponents) {
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

/**
 * Utility function to use when rendering a formatted date string
 *
 * @param dateFormat
 * @param dateObject
 * @returns string
 */
const getFormattedDateFromObject = (dateFormat: DateFormat = "YYYY-MM-DD", dateObject: Response): string => {
  // If an invalid date format is provided, use the default format
  if (!isValidDateFormat(dateFormat)) {
    dateFormat = "YYYY-MM-DD";
  }

  // If the date object is invalid, return a dash
  if (!isValidDateObject(dateObject)) {
    return "-";
  }

  const { YYYY, MM, DD } = dateObject;

  const formattedDate = dateFormat.replace("YYYY", YYYY.toString()).replace("MM", MM.toString().padStart(2, "0")).replace("DD", DD.toString().padStart(2, "0"));

  return formattedDate;
};

/**
 * Check that a date format is valid
 *
 * @param dateFormat
 * @returns boolean
 */
const isValidDateFormat = (dateFormat: DateFormat): boolean => {
  return ["YYYY-MM-DD", "DD-MM-YYYY", "MM-DD-YYYY"].includes(dateFormat);
};

/**
 * Check that a date object is valid
 *
 * @param obj
 * @returns boolean
 */
const isValidDateObject = (obj: unknown): obj is DateObject => {
  return typeof obj === "object" && obj !== null && "YYYY" in obj && "MM" in obj && "DD" in obj && typeof obj["YYYY"] === "number" && typeof obj["MM"] === "number" && typeof obj["DD"] === "number";
};
