import { createHash } from "node:crypto";
import { parse } from "@aws-lambda-powertools/parser";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { SendMessageCommand, SQSClient } from "@aws-sdk/client-sqs";
import { DynamoDBDocument, PutCommand, UpdateCommand } from "@aws-sdk/lib-dynamodb";
import { lambdaWithContextualLogger } from "common";
import { type Either, EitherAsync, Left, Right } from "purify-ts";
import * as uuid from "uuid";
import z from "zod";

type LambdaEvent = Record<string, unknown>;

type LambdaResult = {
  submissionId: string;
};

type SubmissionPayload = {
  formID: string;
  language: string;
  responses: Record<string, unknown>;
  securityAttribute: string;
  fileChecksums?: Record<string, string>;
  version?: number;
  notificationId?: string;
};

const lambdaEventSchema = z.object({
  formID: z.cuid2(),
  language: z.enum(["en", "fr"]),
  responses: z.object(), // TODO: see if we want to restrict this even more
  securityAttribute: z.enum(["Unclassified", "Protected A", "Protected B"]),
  fileChecksums: z.record(z.string(), z.string()).optional(),
  version: z.number().optional(),
  notificationId: z.uuidv4().optional(),
});

const dynamodbClient = DynamoDBDocument.from(
  new DynamoDBClient({
    region: process.env.REGION ?? "ca-central-1",
  }),
);

const sqsClient = new SQSClient({
  region: process.env.REGION ?? "ca-central-1",
});

const SUBMISSION_PROCESSING_REQUEST_DELAY_IN_SECONDS = 5; // Helps ensure the file scanning job is processed first

export const handler = lambdaWithContextualLogger<LambdaEvent, LambdaResult>(({ event, contextualLogger }) => {
  return EitherAsync
    .liftEither(extractSubmissionPayloadFromLambdaEvent(event)) // biome-ignore format: Keep EitherAsync fluent chain vertically aligned
    .ifRight(({ formID }) => contextualLogger.addMetadata("formId", formID))
    .chain((submissionPayload) =>
      saveSubmission(submissionPayload).map(({ submissionId }) => ({
        submissionId,
      })),
    )
    .ifRight(({ submissionId }) => contextualLogger.addMetadata("submissionId", submissionId))
    .chain(({ submissionId }) =>
      enqueueSubmissionProcessingRequest(submissionId).map(({ submissionProcessingRequestId }) => ({
        submissionId,
        submissionProcessingRequestId,
      })),
    )
    .ifRight(({ submissionProcessingRequestId }) => contextualLogger.addMetadata("submissionProcessingRequestId", submissionProcessingRequestId))
    .chain(({ submissionId, submissionProcessingRequestId }) =>
      attachSubmissionProcessingRequestIdToSavedSubmission(submissionId, submissionProcessingRequestId).map(() => ({
        submissionId,
      })),
    )
    .ifRight(() =>
      contextualLogger.log({
        level: "info",
        message: "Submission has been successfully processed",
      }),
    )
    .map(({ submissionId }) => ({ submissionId }) satisfies LambdaResult)
    .ifLeft((error) =>
      contextualLogger.log({
        level: "error",
        message: "An error occurred during execution",
        error: error as Error,
        severityLevel: "1",
      }),
    );
});

function extractSubmissionPayloadFromLambdaEvent(event: LambdaEvent): Either<Error, SubmissionPayload> {
  const parsedResult = parse(event, undefined, lambdaEventSchema, true);

  return parsedResult.success
    ? Right(parsedResult.data satisfies SubmissionPayload)
    : Left(
        new Error("Failed to parse lambda event", {
          cause: parsedResult.error,
        }),
      );
}

function saveSubmission(submissionPayload: SubmissionPayload): EitherAsync<Error, { submissionId: string }> {
  const { securityAttribute, version, ...sanitizedSubmissionPayload } = submissionPayload;

  const responsesHash = createHash("md5").update(JSON.stringify(submissionPayload.responses)).digest("hex"); // We use MD5 here because it is faster to generate and it will only be used as a checksum.

  const submissionId = uuid.v4();

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
            // HasFileKeys: fileKeys !== undefined ? 1 : 0, // TODO: implement
            // ...(fileKeys !== undefined && {
            //   FileKeys: JSON.stringify(fileKeys),
            // }),
            ...(submissionPayload.notificationId !== undefined && {
              NotificationID: submissionPayload.notificationId,
            }),
          },
        }),
      )
      .then(() => ({
        submissionId,
      }))
      .catch((error) => {
        throw new Error("Failed to save submission", {
          cause: error,
        });
      });
  });
}

function enqueueSubmissionProcessingRequest(submissionId: string): EitherAsync<Error, { submissionProcessingRequestId: string }> {
  return EitherAsync(() => {
    return sqsClient
      .send(
        new SendMessageCommand({
          MessageBody: JSON.stringify({
            submissionID: submissionId,
          }),
          DelaySeconds: SUBMISSION_PROCESSING_REQUEST_DELAY_IN_SECONDS,
          QueueUrl: process.env.SQS_URL,
        }),
      )
      .then((commandOutput) => {
        if (commandOutput.MessageId === undefined) {
          throw new Error("MessageId is undefined");
        }

        return { submissionProcessingRequestId: commandOutput.MessageId };
      })
      .catch((error) => {
        throw new Error("Failed to enqueue submission processing request", {
          cause: error,
        });
      });
  });
}

function attachSubmissionProcessingRequestIdToSavedSubmission(submissionId: string, submissionProcessingRequestId: string): EitherAsync<Error, void> {
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
