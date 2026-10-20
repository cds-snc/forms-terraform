import { createHash } from "node:crypto";
import { PutCommand, type PutCommandOutput, UpdateCommand, type UpdateCommandOutput } from "@aws-sdk/lib-dynamodb";
import type { DynamoDbProcessableSubmission } from "common";
import { EitherAsync } from "purify-ts";
import { dynamodbClient } from "./awsServicesConnector.ts";
import type { SubmissionPayload } from "./payload.ts";

export function saveProcessableSubmissionToReliabilityStorage(submissionId: string, submissionPayload: SubmissionPayload, attachmentS3AccessKeys?: string[]): EitherAsync<Error, void> {
  const { securityAttribute, version, ...sanitizedSubmissionPayload } = submissionPayload;

  const responsesHash = createHash("md5").update(JSON.stringify(submissionPayload.responses)).digest("hex"); // We use MD5 here because it is faster to generate and it will only be used as a checksum.

  return EitherAsync<Error, PutCommandOutput>(() =>
    dynamodbClient.send(
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
        } satisfies DynamoDbProcessableSubmission,
      }),
    ),
  )
    .void()
    .mapLeft((error) => new Error("Failed to save processable submission to reliability storage", { cause: error }));
}

export function attachSubmissionProcessingRequestIdToProcessableSubmission(submissionId: string, submissionProcessingRequestId: string): EitherAsync<Error, void> {
  return EitherAsync<Error, UpdateCommandOutput>(() =>
    dynamodbClient.send(
      new UpdateCommand({
        TableName: process.env.DYNAMODB_RELIABILITY_QUEUE_TABLE_NAME,
        Key: { SubmissionID: submissionId },
        UpdateExpression: "SET SendReceipt = :receiptId",
        ExpressionAttributeValues: { ":receiptId": submissionProcessingRequestId },
      }),
    ),
  )
    .void()
    .mapLeft((error) => new Error("Failed to attach submission processing request identifier to processable submission", { cause: error }));
}
