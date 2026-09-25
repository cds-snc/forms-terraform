import { createHash } from "node:crypto";
import { PutCommand, type PutCommandOutput } from "@aws-sdk/lib-dynamodb";
import type { DynamoDbProcessableSubmission } from "common";
import { EitherAsync } from "purify-ts";
import { dynamodbClient } from "./awsServicesConnector.ts";
import type { SubmissionPayload } from "./payload.ts";

export function saveProcessableSubmissionToReliabilityStorage(submissionId: string, submissionPayload: SubmissionPayload, attachmentS3AccessKeys?: string[]): EitherAsync<Error, void> {
  const responsesHash = createHash("md5").update(JSON.stringify(submissionPayload.responses)).digest("hex"); // We use MD5 here because it is faster to generate and it will only be used as a checksum.

  return EitherAsync<Error, PutCommandOutput>(() =>
    dynamodbClient.send(
      new PutCommand({
        TableName: process.env.DYNAMODB_RELIABILITY_QUEUE_TABLE_NAME,
        Item: {
          SubmissionID: submissionId,
          FormID: submissionPayload.formID,
          SendReceipt: "unknown", // We have to keep this property set to 'unknown' as it will be used by the the two submission attachments related lambda functions (file-upload-cleanup/processor)
          FormSubmissionLanguage: submissionPayload.language,
          FormData: JSON.stringify({ responses: submissionPayload.responses }), // Only adding responses in there since this is just what the Reliability lambda needs. Still have to keep it under a 'responses' JSON object to make it compatible with the current Reliability lambda (pre revamp)
          CreatedAt: Date.now(),
          SecurityAttribute: submissionPayload.securityAttribute,
          Version: submissionPayload.version ?? 1,
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
