import { createHash } from "node:crypto";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocument, PutCommand, UpdateCommand } from "@aws-sdk/lib-dynamodb";
import { EitherAsync } from "purify-ts";
import type { SubmissionPayload } from "./payload.ts";

const dynamodbClient = DynamoDBDocument.from(
  new DynamoDBClient({
    region: process.env.REGION ?? "ca-central-1",
  }),
);

export function saveSubmissionToReliabilityStorage(submissionId: string, submissionPayload: SubmissionPayload, attachmentS3AccessKeys?: string[]): EitherAsync<Error, void> {
  const { securityAttribute, version, ...sanitizedSubmissionPayload } = submissionPayload;

  const responsesHash = createHash("md5").update(JSON.stringify(submissionPayload.responses)).digest("hex"); // We use MD5 here because it is faster to generate and it will only be used as a checksum.

  return EitherAsync(() => {
    return dynamodbClient
      .send(
        new PutCommand({
          TableName: process.env.DYNAMODB_RELIABILITY_QUEUE_TABLE_NAME,
          Item: {
            SubmissionID: submissionId,
            FormID: submissionPayload.formID,
            SendReceipt: "unknown",
            FormSubmissionLanguage: submissionPayload.language,
            FormData: JSON.stringify(sanitizedSubmissionPayload),
            CreatedAt: Date.now(),
            SecurityAttribute: securityAttribute,
            Version: version ?? 1,
            FormSubmissionHash: responsesHash,
            HasFileKeys: attachmentS3AccessKeys !== undefined ? 1 : 0,
            ...(attachmentS3AccessKeys !== undefined && {
              FileKeys: JSON.stringify(attachmentS3AccessKeys),
            }),
            ...(submissionPayload.notificationId !== undefined && {
              NotificationID: submissionPayload.notificationId,
            }),
          },
        }),
      )
      .then(() => {})
      .catch((error) => {
        throw new Error("Failed to save submission", {
          cause: error,
        });
      });
  });
}

export function attachSubmissionProcessingRequestIdToSavedSubmission(submissionId: string, submissionProcessingRequestId: string): EitherAsync<Error, void> {
  return EitherAsync(() => {
    return dynamodbClient
      .send(
        new UpdateCommand({
          TableName: process.env.DYNAMODB_RELIABILITY_QUEUE_TABLE_NAME,
          Key: {
            SubmissionID: submissionId,
          },
          UpdateExpression: "SET SendReceipt = :receiptId",
          ExpressionAttributeValues: {
            ":receiptId": submissionProcessingRequestId,
          },
        }),
      )
      .then(() => {})
      .catch((error) => {
        throw new Error("Failed to attach submission processing request identifier to saved submission", {
          cause: error,
        });
      });
  });
}
