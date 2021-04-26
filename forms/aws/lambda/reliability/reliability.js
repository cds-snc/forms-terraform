const { DynamoDBClient, GetItemCommand, DeleteItemCommand } = require("@aws-sdk/client-dynamodb");
const { NotifyClient } = require("notifications-node-client");
const convertMessage = require("markdown");
const REGION = process.env.REGION;

exports.handler = async function (event) {
  let submissionIDPlaceholder = "";
  try {
    const message = JSON.parse(event.Records[0].body);
    const { submissionID, sendReceipt, formSubmission } = await getSubmission(message)
      .then((messageData) => ({
        submissionID: messageData.Item.SubmissionID.S,
        sendReceipt: messageData.Item.SendReceipt.S,
        formSubmission: JSON.parse(messageData.Item.Data.S) || null,
      }))
      .catch((err) => {
        console.error("Could not sucessfully retrieve data");
        throw Error(err);
      });
    submissionIDPlaceholder = submissionID;
    // Check if form data exists or was already processed.
    if (formSubmission === null || typeof formSubmission === "undefined") {
      // Ack and remove message from queue if it doesn't exist in the DB
      console.warn(
        `No corresponding submission for Submission ID: ${submissionID} in the reliability database`
      );
      return { statusCode: 202, body: "Data no longer exists in DB" };
    }
    // Process request and format for Notify

    const templateID = "92096ac6-1cc5-40ae-9052-fffdb8439a90";
    const notify = new NotifyClient(
      "https://api.notification.canada.ca",
      process.env.NOTIFY_API_KEY
    );
    const emailBody = convertMessage(formSubmission);
    const messageSubject = formSubmission.form.titleEn + " Submission";
    // Need to get this from the submission now.. not the app.
    const submissionFormat = formSubmission.submission;
    // Send to Notify

    if ((submissionFormat !== null) & (submissionFormat.email !== "")) {
      await notify
        // Send to static email address and not submission address in form
        .sendEmail(templateID, "forms-formulaires@cds-snc.ca", {
          personalisation: {
            subject: messageSubject,
            formResponse: emailBody,
          },
          reference: submissionID,
        })
        .catch((err) => {
          console.error(`Sending to Notify error: ${JSON.stringify(err)}`);
          throw err;
        });
      console.log(
        `Sucessfully processed SQS message ${sendReceipt} for Submission ${submissionID}`
      );
      // Remove data
      await removeSubmission(message).catch((err) => {
        // Not throwing an error back to SQS because the message was
        // sucessfully processed by Notify.  Only cleanup required.
        console.error(
          `Could not delete submission ${submissionID} from DB.  Error: ${
            typeof err === "object" ? JSON.stringify(err) : err
          }`
        );
      });

      return { statusCode: 202, body: "Received by Notify" };
    } else {
      throw Error("Form can not be submitted due to missing Submission Parameters");
    }
  } catch (err) {
    console.error(`Error in processing, submission ${submissionIDPlaceholder} not processed.`);
    // By rethrowing the error below the message will not be deleted from the queue.
    throw Error(err);
  }
};

async function getSubmission(message) {
  try {
    const db = new DynamoDBClient({ region: REGION });
    const DBParams = {
      TableName: "ReliabilityQueue",
      //prettier-ignore
      Key: {
        SubmissionID: { "S": message.submissionID },
      },
      ProjectExpression: "SubmissionID,SendReceipt,FormData",
    };
    //save data to DynamoDB
    return db.send(new GetItemCommand(DBParams));
  } catch (err) {
    throw Error(err);
  }
}

async function removeSubmission(message) {
  try {
    const db = new DynamoDBClient({ region: REGION });
    const DBParams = {
      TableName: "ReliabilityQueue",
      Key: {
        SubmissionID: { S: message.submissionID },
      },
    };
    //remove data fron DynamoDB
    return db.send(new DeleteItemCommand(DBParams));
  } catch (err) {
    throw Error(err);
  }
}
