import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { PutCommand, UpdateCommand } from "@aws-sdk/lib-dynamodb";
import { SQSClient, SendMessageCommand } from "@aws-sdk/client-sqs";
import { Handler } from "aws-lambda";
import { v4 } from "uuid";
import { createHash } from "crypto";
import { generateFileURLs } from "./lib/fileUpload.js";

type AnyObject = {
  [key: string]: any;
};

const awsProperties = {
  region: process.env.REGION ?? "ca-central-1",
};

const dynamodb = new DynamoDBClient(awsProperties);

const sqs = new SQSClient(awsProperties);

/*
Params:
  formID - ID of form,
  language - form submission language "fr" or "en",
  responses - form responses: {formID, securityAttribute, questionID: answer}
  securityAttribute - string of security classification
*/
export const handler: Handler = async (submission: AnyObject) => {
  const submissionId = v4();

  try {
    const { fileKeys, fileURLMap } = await generateFileURLs(submissionId, submission);
    await saveSubmission(submissionId, submission, fileKeys);

    // If we have files we return the file keys so that the client can upload them to S3
    if (fileKeys.length > 0) {
      return { status: true, submissionId, fileURLMap };
    }

    const receiptId = await enqueueReliabilityProcessingRequest(submissionId);

    await updateReceiptIdForSubmission(submissionId, receiptId);

    console.log(
      JSON.stringify({
        level: "info",
        status: "success",
        sqsMessage: receiptId,
        submissionId: submissionId,
      })
    );

    return { status: true, submissionId };
  } catch (error) {
    console.error(
      JSON.stringify({
        level: "error",
        severity: 1, // this will trigger an alert to on-call team
        status: "failed",
        submissionId: submissionId,
        msg: (error as Error).message,
        details: JSON.stringify(error),
      })
    );

    return { status: false };
  }
};

const enqueueReliabilityProcessingRequest = async (submissionId: string): Promise<string> => {
  try {
    const sendMessageCommandOutput = await sqs.send(
      new SendMessageCommand({
        MessageBody: JSON.stringify({
          submissionID: submissionId,
        }),
        // Helps ensure the file scanning job is processed first
        DelaySeconds: 5,
        QueueUrl: process.env.SQS_URL,
      })
    );

    if (!sendMessageCommandOutput.MessageId) {
      throw new Error("Received null SQS message identifier");
    }

    return sendMessageCommandOutput.MessageId;
  } catch (error) {
    throw new Error("Could not enqueue reliability processing request. " + JSON.stringify(error));
  }
};

const saveSubmission = async (
  submissionId: string,
  formData: AnyObject,
  fileKeys: string[]
): Promise<void> => {
  try {
    const securityAttribute = formData.securityAttribute ?? "Protected A";
    delete formData.securityAttribute;

    const timeStamp = Date.now();

    const alteredFormDataAsString = JSON.stringify(formData);

    const formResponsesAsString = JSON.stringify(formData.responses);

    const fileKeysAsString = JSON.stringify(fileKeys);

    const formResponsesAsHash = createHash("md5").update(formResponsesAsString).digest("hex"); // We use MD5 here because it is faster to generate and it will only be used as a checksum.

    console.log(
      JSON.stringify({
        level: "info",
        msg: `MD5 hash ${formResponsesAsHash} was calculated for submission ${submissionId} (formId: ${formData.formID}).`,
      })
    );

    await dynamodb.send(
      new PutCommand({
        TableName: "ReliabilityQueue",
        Item: {
          SubmissionID: submissionId,
          FormID: formData.formID,
          SendReceipt: "unknown",
          FormSubmissionLanguage: formData.language,
          FormData: alteredFormDataAsString,
          CreatedAt: timeStamp,
          SecurityAttribute: securityAttribute,
          FormSubmissionHash: formResponsesAsHash,
          FileKeys: fileKeysAsString,
        },
      })
    );
  } catch (error) {
    throw new Error(
      `Could not save submission to Reliability Temporary Storage. Reason: ${
        (error as Error).message
      }`
    );
  }
};

const updateReceiptIdForSubmission = async (
  submissionId: string,
  receiptId: string
): Promise<void> => {
  try {
    await dynamodb.send(
      new UpdateCommand({
        TableName: "ReliabilityQueue",
        Key: {
          SubmissionID: submissionId,
        },
        UpdateExpression: "SET SendReceipt = :receiptId",
        ExpressionAttributeValues: {
          ":receiptId": receiptId,
        },
      })
    );
  } catch (error) {
    console.warn(
      JSON.stringify({
        level: "warn",
        submissionId: submissionId,
        msg: `Could not update submission in reliability queue table with receipt identifier`,
        error: (error as Error).message,
      })
    );
  }
};
