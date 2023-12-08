import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { PutCommand, UpdateCommand } from "@aws-sdk/lib-dynamodb";
import { SQSClient, SendMessageCommand } from "@aws-sdk/client-sqs";
import { Handler } from "aws-lambda";
import { v4 } from "uuid";
import { createHash } from "crypto";

type AnyObject = {
  [key: string]: any;
};

const awsProperties = {
  region: process.env.REGION ?? "ca-central-1",
  ...(process.env.LOCALSTACK === "true" && {
    endpoint: "http://host.docker.internal:4566",
  }),
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
    await saveSubmission(submissionId, submission);

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

    return { status: true };
  } catch (error) {
    console.error(
      JSON.stringify({
        level: "error",
        severity: 1,
        status: "failed",
        submissionId: submissionId,
        msg: (error as Error).message,
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
        MessageDeduplicationId: submissionId,
        MessageGroupId: "Group-" + submissionId,
        QueueUrl: process.env.SQS_URL,
      })
    );

    if (!sendMessageCommandOutput.MessageId)
      throw new Error("Received null SQS message identifier");

    return sendMessageCommandOutput.MessageId;
  } catch (error) {
    console.error(JSON.stringify(error));
    throw new Error("Could not enqueue reliability processing request");
  }
};

const saveSubmission = async (submissionId: string, formData: AnyObject): Promise<void> => {
  try {
    const securityAttribute = formData.securityAttribute ?? "Protected A";
    delete formData.securityAttribute;

    const timeStamp = Date.now().toString();

    const alteredFormDataAsString = JSON.stringify(formData);

    const formResponsesAsString = JSON.stringify(formData.responses);
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
          CreatedAt: Number(timeStamp),
          SecurityAttribute: securityAttribute,
          FormSubmissionHash: formResponsesAsHash,
        },
      })
    );
  } catch (error) {
    console.error(JSON.stringify(error));
    throw new Error("Could not save submission to Reliability Temporary Storage");
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
