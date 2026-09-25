import { DeleteCommand, GetCommand, UpdateCommand } from "@aws-sdk/lib-dynamodb";
import { type DynamoDbProcessableSubmission, DynamoDbProcessableSubmissionProjectionExpression } from "common";
import { EitherAsync, Just, type Maybe, Nothing } from "purify-ts";
import { dynamodbClient } from "./awsServicesConnector.ts";

export type ProcessableSubmission = {
  id: string;
  associatedFormId: string;
  createdAt: number;
  language: string;
  securityAttribute: string;
  version: number;
  responsesAsJson: string;
  responsesHash: string;
  attachmentPathsAsJson?: string;
  notificationId?: string;
  hasBeenSuccessfullyProcessedByEmailPipeline: boolean;
};

export function retrieveProcessableSubmission(id: string): EitherAsync<Error, Maybe<ProcessableSubmission>> {
  return EitherAsync(() =>
    dynamodbClient.send(
      new GetCommand({
        TableName: process.env.DYNAMODB_RELIABILITY_QUEUE_TABLE_NAME,
        Key: {
          SubmissionID: id,
        },
        ProjectionExpression: DynamoDbProcessableSubmissionProjectionExpression,
      }),
    ),
  )
    .map(({ Item }) => {
      if (Item === undefined) {
        return Nothing;
      }

      const retrievedSubmission = Item as DynamoDbProcessableSubmission;

      // We do this to make it compatible with the current Submission lambda (pre revamp)
      const { responses } = JSON.parse(retrievedSubmission.FormData) as { responses: Record<string, unknown> };

      return Just({
        id,
        associatedFormId: retrievedSubmission.FormID,
        createdAt: retrievedSubmission.CreatedAt,
        language: retrievedSubmission.FormSubmissionLanguage,
        securityAttribute: retrievedSubmission.SecurityAttribute,
        version: retrievedSubmission.Version,
        responsesAsJson: JSON.stringify(responses),
        responsesHash: retrievedSubmission.FormSubmissionHash,
        attachmentPathsAsJson: retrievedSubmission.FileKeys,
        notificationId: retrievedSubmission.NotificationID,
        hasBeenSuccessfullyProcessedByEmailPipeline: retrievedSubmission.NotifyProcessed ?? false,
      } satisfies ProcessableSubmission);
    })
    .mapLeft((error) => new Error("Failed to retrieve processable submission", { cause: error }));
}

export function markProcessableSubmissionForDeletionIn30days(id: string): EitherAsync<Error, void> {
  return EitherAsync(() =>
    dynamodbClient.send(
      new UpdateCommand({
        TableName: process.env.DYNAMODB_RELIABILITY_QUEUE_TABLE_NAME,
        Key: { SubmissionID: id },
        UpdateExpression: "SET #ttl = :ttl",
        ExpressionAttributeNames: { "#ttl": "TTL" },
        ExpressionAttributeValues: { ":ttl": Math.floor(Date.now() / 1000) + 2592000 },
        ReturnValues: "NONE",
      }),
    ),
  )
    .void()
    .mapLeft((error) => new Error("Failed to mark processable submission for deletion", { cause: error }));
}

export function deleteProcessableSubmission(id: string): EitherAsync<Error, void> {
  return EitherAsync(() =>
    dynamodbClient.send(
      new DeleteCommand({
        TableName: process.env.DYNAMODB_RELIABILITY_QUEUE_TABLE_NAME,
        Key: {
          SubmissionID: id,
        },
      }),
    ),
  )
    .void()
    .mapLeft((error) => new Error("Failed to delete processable submission", { cause: error }));
}
