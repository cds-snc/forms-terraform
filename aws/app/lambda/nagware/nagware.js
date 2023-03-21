const { retrieveFormResponsesOver28DaysOld } = require("dynamodbDataLayer");
const { getFormNameAndOwnerEmailAddress } = require("postgreSQLDataLayer");
const { notifyFormsTeam, reportError } = require("slackNotification");
const { notifyFormOwner } = require("emailNotification");

const ENABLED_IN_STAGING = true;

exports.handler = async (event) => {
  try {
    if (!ENABLED_IN_STAGING && process.env.ENVIRONMENT === "staging") return;

    const oldestFormResponseByFormID = await findOldestFormResponseByFormID();
    await nag(oldestFormResponseByFormID);

    return {
      statusCode: "SUCCESS",
    };
  } catch (error) {
    await reportError(error.message);

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

async function nag(oldestFormResponseByFormID) {
  for (const formResponse of oldestFormResponseByFormID) {
    const diffMs = Math.abs(Date.now() - formResponse.createdAt);
    const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));

    if (diffDays > 45) {
      await notifyFormsTeam(formResponse.formID, diffDays);
    } else {
      const formNameAndOwnerEmailAddress = await getFormNameAndOwnerEmailAddress(formResponse.formID);
      await notifyFormOwner(formResponse.formID, formNameAndOwnerEmailAddress.name, formNameAndOwnerEmailAddress.emailAddress);
    }
  }
}