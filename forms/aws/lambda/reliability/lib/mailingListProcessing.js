const axios = require("axios");
const { LambdaClient, InvokeCommand } = require("@aws-sdk/client-lambda");
const { removeSubmission, formatError } = require("dataLayer");
// Process request and send to Mailing List Manager

const REGION = process.env.REGION;

// get ircc configuration file from env variable. This is a base64 encoded string
const irccConfig = process.env.IRCC_CONFIG
  ? JSON.parse(Buffer.from(process.env.IRCC_CONFIG, "base64").toString())
  : undefined;

const listManagerHost = process.env.LIST_MANAGER_HOST;

const listManagerApiKey = process.env.LIST_MANAGER_API_KEY;

module.exports = async (submissionID, sendReceipt, formSubmission, message) => {
  const { responses, formID } = formSubmission;
  const form = await getFormTemplate(formID);

  // get program and language values from submission using the ircc config refrenced ids
  const programs = JSON.parse(responses[irccConfig.programFieldID]);
  const programList = programs.value;

  const languages = JSON.parse(responses[irccConfig.languageFieldID]);

  const languageList = languages.value;

  const contact = responses[irccConfig.contactFieldID];

  // get the type of contact field from the form template
  const contactFieldFormElement = form.elements.filter(
    (value) => value.id === irccConfig.contactFieldID
  );

  const contactFieldType =
    contactFieldFormElement.length > 0
      ? contactFieldFormElement[0].properties.validation?.type
      : false;

  if (contactFieldType) {
    // forEach slower than a for loop https://stackoverflow.com/questions/43821759/why-array-foreach-is-slower-than-for-loop-in-javascript
    // yes its a double loop O(n^2) but we know n <= 4
    for (let i = 0; i < languageList.length; i++) {
      for (let j = 0; j < programList.length; j++) {
        const language = languageList[i];
        const program = programList[j];
        let listID;
        // try getting the list id from the config json. If it doesn't exist fail gracefully, log the message and send 500 error
        // 500 error because this is a misconfiguration on our end its not the users fault i.e. 4xx
        try {
          listID = irccConfig.listMapping[language][program][contactFieldType];
        } catch (err) {
          console.error(
            `IRCC config does not contain the following path ${language}.${program}.${contactFieldType}`
          );
          throw new Error(`Sending to Mailing List Error: ${JSON.stringify(err)}`);
        }

        let response;
        try {
          // Now we create the subscription
          response = await axios.post(
            `${listManagerHost}/subscription`,
            {
              [contactFieldType]: contact,
              list_id: listID,
            },
            {
              headers: {
                Authorization: listManagerApiKey,
              },
            }
          );
        } catch (err) {
          console.error(
            `Subscription failed with status ${response.status} and message ${response.data}`
          );
          throw new Error(`Sending to Mailing List Error: ${JSON.stringify(err)}`);
        }

        // subscription is successfully created... log the id and return 200
        if (response.status === 200) {
          console.log(
            `{"status": "success", "submissionID": "${submissionID}", "sqsMessage":"${sendReceipt}", "method":"mailing_list"}`
          );

          // Remove data
          return await removeSubmission(message).catch((err) => {
            // Not throwing an error back to SQS because the message was
            // sucessfully processed by Notify.  Only cleanup required.
            console.warn(
              `{"status": "failed", "submissionID": "${submissionID}", "error": "Can not delete entry from reliability db.  Error:${formatError(
                err
              )}", "method":"notify"}`
            );
          });
        }
        // otherwise something has failed... not the users issue hence 500
        else {
          throw new Error(
            `Subscription failed with status ${response.status} and message ${response.data}`
          );
        }
      }
    }
  } else {
    throw new Error(
      `Not able to determine type of contact field for form ${formSubmission.formID}`
    );
  }
};

const getFormTemplate = async (formID) => {
  const lambdaClient = new LambdaClient({ region: REGION });
  const encoder = new TextEncoder();

  const command = new InvokeCommand({
    FunctionName: "Templates",
    Payload: encoder.encode(
      JSON.stringify({
        method: "GET",
        formID,
      })
    ),
  });
  return await lambdaClient
    .send(command)
    .then((response) => {
      const decoder = new TextDecoder();
      const payload = decoder.decode(response.Payload);
      if (response.FunctionError) {
        cosole.error("Lambda Template Client not successful");
        return null;
      } else {
        console.info("Lambda Template Client successfully triggered");

        const response = JSON.parse(payload);
        const { records } = response.data;
        if (records?.length === 1 && records[0].formConfig.form) {
          return {
            formID,
            ...records[0].formConfig.form,
          };
        }
        return null;
      }
    })
    .catch((err) => {
      console.error(err);
      throw new Error("Could not process request with Lambda Templates function");
    });
};
