import { GetCommand } from "@aws-sdk/lib-dynamodb";
import { type DynamoDbProcessableSubmission, DynamoDbProcessableSubmissionProjectionExpression } from "common";
import { type Either, EitherAsync, Left, Right } from "purify-ts";
import { dynamodbClient } from "./awsServicesConnector.ts";

type ProcessableSubmission = {
  id: string;
  associatedFormId: string;
  responses: Record<string, unknown>;
  language: string;
};

export function retrieveProcessableSubmissionFromReliabilityStorage(submissionId: string): EitherAsync<Error, Either<null, ProcessableSubmission>> {
  return EitherAsync(() =>
    dynamodbClient.send(
      new GetCommand({
        TableName: process.env.DYNAMODB_RELIABILITY_QUEUE_TABLE_NAME,
        Key: {
          SubmissionID: submissionId,
        },
        ProjectionExpression: DynamoDbProcessableSubmissionProjectionExpression,
      }),
    ),
  )
    .map(({ Item }) => {
      if (Item === undefined) {
        return Left(null);
      }

      const retrievedSubmission = Item as DynamoDbProcessableSubmission;

      return Right({
        id: submissionId,
        associatedFormId: retrievedSubmission.FormID,
        responses: JSON.parse(retrievedSubmission.FormData),
        language: retrievedSubmission.FormSubmissionLanguage,
      });
    })
    .mapLeft(
      (error) =>
        new Error("Failed to retrieve processable submission from reliability storage", {
          cause: error,
        }),
    );
}

// const submissionID = messageData.Item?.SubmissionID ?? message.submissionID;
//     const formID =
//       // dynamodb client could possibly return as a number due to early form identifiers being numeric
//       typeof messageData.Item?.FormID === "string"
//         ? messageData.Item?.FormID
//         : (messageData.Item?.FormID.toString() ?? null);
//     const formSubmission = messageData.Item?.FormData
//       ? JSON.parse(messageData.Item?.FormData)
//       : null;
//     const language = messageData.Item?.FormSubmissionLanguage ?? "en";
//     const securityAttribute = String(messageData.Item?.SecurityAttribute ?? "Protected A");
//     const version = Number(messageData.Item?.Version ?? 1);
//     const createdAt = messageData.Item?.CreatedAt ?? null;
//     const notifyProcessed = messageData.Item?.NotifyProcessed ?? false;
//     sendReceipt = messageData.Item?.SendReceipt ?? null;
//     const formSubmissionHash = messageData.Item?.FormSubmissionHash ?? null;
//     const fileKeys = messageData.Item?.FileKeys ? JSON.parse(messageData.Item?.FileKeys) : [];
//     const notificationId: string | undefined = messageData.Item?.NotificationID;
