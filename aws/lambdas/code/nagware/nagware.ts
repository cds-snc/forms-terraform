import {
  retrieveFormResponsesOver28DaysOld,
  deleteOldTestResponses,
} from "./lib/dynamodbDataLayer.js";
import { getTemplateInfo } from "./lib/templates.js";
import { notifyFormOwner } from "./lib/emailNotification.js";
import { Handler } from "aws-lambda";

type NotificationSettings = {
  shouldSendEmail: boolean;
  shouldSendSlackNotification: boolean;
};

type NagwareDetection = {
  formTimestamp: number;
  formId: string;
  formName: string;
  owners: { name: string; email: string; }[]
};

export const handler: Handler = async () => {
  try {
    const oldestFormResponseByFormID = await findOldestFormResponseByFormID();

    const isSunday = new Date().getDay() == 0; // 0 is Sunday

    await nagOrDelete(oldestFormResponseByFormID, { shouldSendEmail: isSunday == false, shouldSendSlackNotification: isSunday });

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

async function nagOrDelete(oldestFormResponseByFormID: { formID: string; createdAt: number }[], notificationSettings: NotificationSettings) {
  for (const formResponse of oldestFormResponseByFormID) {
    try {
      const templateInfo = await getTemplateInfo(formResponse.formID);

      if (templateInfo.isPublished) {
        if (notificationSettings.shouldSendEmail) {
          for (const owner of templateInfo.owners) {
            await notifyFormOwner(formResponse.formID, templateInfo.formName, owner.email);
          }
        }

        logNagwareDetection({ 
          formTimestamp: formResponse.createdAt, 
          formId: formResponse.formID, 
          formName: templateInfo.formName, 
          owners: templateInfo.owners,
        }, notificationSettings.shouldSendSlackNotification);
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

function logNagwareDetection(nagwareDetection: NagwareDetection, shouldSendSlackNotification: boolean) {
  const diffMs = Math.abs(Date.now() - nagwareDetection.formTimestamp);
  const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

  if (diffDays > 45) {
    console.warn(
      JSON.stringify({
        level: shouldSendSlackNotification ? "warn" : "info",
        msg: `
*Form*\n
Identifier: ${nagwareDetection.formId}\n
Name: ${nagwareDetection.formName}
\n*Owner(s)*\n
${nagwareDetection.owners.map((owner) => `${owner.name} (${owner.email})`).join("\n")}
\n*Oldest response*\n
${diffDays} days since submission
`,
      })
    );
  }
}