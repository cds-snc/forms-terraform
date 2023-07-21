const { retrieveFormResponsesOver28DaysOld, deleteOldTestResponses } = require("dynamodbDataLayer");
const { getTemplateInfo } = require("templates");
const { notifyFormOwner } = require("emailNotification");

const ENABLED_IN_STAGING = true;

exports.handler = async () => {
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
        error: error.message,
      })
    );

    return {
      statusCode: "ERROR",
      error: error.message,
    };
  }
};

async function findOldestFormResponseByFormID() {
  const unsavedFormResponses = await retrieveFormResponsesOver28DaysOld("New");
  const unconfirmedFormResponses = await retrieveFormResponsesOver28DaysOld("Downloaded");

  const reduceResult = unsavedFormResponses.concat(unconfirmedFormResponses).reduce((acc, curr) => {
    const { formID, createdAt } = curr;

    if (acc[formID] && acc[formID].createdAt < createdAt) {
      return acc;
    } else {
      acc[formID] = curr;
      return acc;
    }
  }, {});

  return Object.values(reduceResult);
}

async function nagOrDelete(oldestFormResponseByFormID) {
  for (const formResponse of oldestFormResponseByFormID) {
    const diffMs = Math.abs(Date.now() - formResponse.createdAt);
    const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

    const templateInfo = await getTemplateInfo(formResponse.formID);
    try {
      if(templateInfo.isPublished) {
        if (diffDays > 45) {
          console.warn(
            JSON.stringify({
              level: "warn",
              msg: `Vault Nagware - ${diffDays} days old form response was detected. Form ID : ${formResponse.formID}.`,
            })
          );
        } else {
          for (const emailAddress of templateInfo.emailAddresses) {
            await notifyFormOwner(
              formResponse.formID,
              templateInfo.formName,
              emailAddress
            );
          }
        }
      }
      else {
        // delete form response if form is not published and older than 28 days
        await deleteOldTestResponses(formResponse.formID);
      }
    } catch (error) {
      // Error Message will be sent to slack
      console.error(
        JSON.stringify({
          level: "error",
          msg: `Failed to send nagware for form ID ${formResponse.formID} .`,
          error: error.message,
        })
      );
      // Continue to attempt to send Nagware even if one fails
    }
  }
}
