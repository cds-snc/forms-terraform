import {
  retrieveFormResponsesOver28DaysOld,
  deleteOldTestResponses,
} from "./lib/dynamodbDataLayer.js";
import { getTemplateInfo } from "./lib/templates.js";
import { notifyFormOwner } from "./lib/emailNotification.js";
import { Handler } from "aws-lambda";

const ENABLED_IN_STAGING = true;

async function findOldestFormResponseByFormID() {
  const unsavedFormResponses = await retrieveFormResponsesOver28DaysOld("New");
  const unconfirmedFormResponses = await retrieveFormResponsesOver28DaysOld("Downloaded");

  const reduceResult = unsavedFormResponses.concat(unconfirmedFormResponses).reduce((acc, curr) => {
    const { formID, createdAt } = curr;

    const previousEntry = acc[formID];

    if (previousEntry && previousEntry?.createdAt < createdAt) {
      return acc;
    } else {
      acc[formID] = curr;
      return acc;
    }
  }, {} as { [key: string]: { formID: string; createdAt: number } });

  return Object.values(reduceResult);
}

async function nagOrDelete(oldestFormResponseByFormID: { formID: string; createdAt: number }[]) {
  for (const formResponse of oldestFormResponseByFormID) {
    const diffMs = Math.abs(Date.now() - formResponse.createdAt);
    const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

    try {
      const templateInfo = await getTemplateInfo(formResponse.formID);

      if (templateInfo.isPublished) {
        if (diffDays > 45) {
          console.warn(
            JSON.stringify({
              level: "warn",
              msg: `
*Form*\n
Identifier: ${formResponse.formID}\n
Name: ${templateInfo.formName}
\n*Owner(s)*\n
${templateInfo.owners.map((owner) => `${owner.name} (${owner.email})`).join("\n")}
\n*Oldest response*\n
${diffDays} days since submission
`,
            })
          );
        } else {
          for (const owner of templateInfo.owners) {
            await notifyFormOwner(formResponse.formID, templateInfo.formName, owner.email);
          }
        }
      } else {
        // Delete form response if form is not published and older than 28 days
        await deleteOldTestResponses(formResponse.formID);
      }
    } catch (error) {
      // Error Message will be sent to slack
      console.error(
        JSON.stringify({
          level: "error",
          msg: `Failed to send nagware for form ID ${formResponse.formID} .`,
          error: (error as Error).message,
        })
      );
      // Continue to attempt to send Nagware even if one fails
    }
  }
}

export const handler: Handler = async () => {
  try {
    if (!ENABLED_IN_STAGING && process.env.ENVIRONMENT === "staging") return;

    const oldestFormResponseByFormID = await findOldestFormResponseByFormID();
    await nagOrDelete(oldestFormResponseByFormID);

    return {
      statusCode: "SUCCESS",
    };
  } catch (error) {
    // Error Message will be sent to slack
    console.error(
      JSON.stringify({
        level: "error",
        msg: "Failed to run Nagware.",
        error: (error as Error).message,
      })
    );

    return {
      statusCode: "ERROR",
      error: (error as Error).message,
    };
  }
};
