import { DynamoDBDocument, PutCommand, UpdateCommand } from "@aws-sdk/lib-dynamodb";
import { mockClient } from "aws-sdk-client-mock";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import type { SubmissionPayload } from "../../src/lib/payload.ts";
import { attachSubmissionProcessingRequestIdToProcessableSubmission, saveProcessableSubmissionToReliabilityStorage } from "../../src/lib/storage.ts";

const dynamodbMock = mockClient(DynamoDBDocument);

const submissionId = "submission-id";
const submissionProcessingRequestId = "submission-processing-request-id";
const submissionPayload: SubmissionPayload = {
  formID: "form-id",
  language: "en",
  securityAttribute: "Unclassified",
  version: 3,
  responses: { 1: "firstResponse", 2: "secondResponse" },
};

describe("saveProcessableSubmissionToReliabilityStorage", () => {
  beforeAll(() => {
    vi.stubEnv("DYNAMODB_RELIABILITY_QUEUE_TABLE_NAME", "dynamodb_table_name");
    vi.setSystemTime(new Date("2026-08-08T08:08:08.888Z"));
  });

  afterEach(() => {
    dynamodbMock.reset();
  });

  it("saves the submission to reliability storage", async () => {
    dynamodbMock.on(PutCommand).resolves({});

    const result = await saveProcessableSubmissionToReliabilityStorage(submissionId, submissionPayload).run();

    expect(result.extract()).toEqual(undefined);

    expect(dynamodbMock.commandCalls(PutCommand).length).toEqual(1);
    expect(dynamodbMock.commandCalls(PutCommand)[0].args[0].input).toEqual({
      TableName: process.env.DYNAMODB_RELIABILITY_QUEUE_TABLE_NAME,
      Item: {
        SubmissionID: "submission-id",
        FormID: "form-id",
        SendReceipt: "unknown",
        FormSubmissionLanguage: "en",
        FormData: '{"formID":"form-id","language":"en","responses":{"1":"firstResponse","2":"secondResponse"}}',
        CreatedAt: 1786176488888,
        SecurityAttribute: "Unclassified",
        Version: 3,
        FormSubmissionHash: "c2225caf1d91bddb29f4a1bc10db474a",
        HasFileKeys: 0,
      },
    });
  });

  it("defaults the version to 1 when no version is provided", async () => {
    dynamodbMock.on(PutCommand).resolves({});

    await saveProcessableSubmissionToReliabilityStorage(submissionId, { ...submissionPayload, version: undefined }).run();

    expect(dynamodbMock.commandCalls(PutCommand).length).toEqual(1);
    expect(dynamodbMock.commandCalls(PutCommand)[0].args[0].input).toMatchObject({
      Item: {
        Version: 1,
      },
    });
  });

  it("includes attachment S3 access keys when provided", async () => {
    dynamodbMock.on(PutCommand).resolves({});

    const attachmentS3AccessKeys = ["attachment-key-1", "attachment-key-2"];

    await saveProcessableSubmissionToReliabilityStorage(submissionId, submissionPayload, attachmentS3AccessKeys).run();

    expect(dynamodbMock.commandCalls(PutCommand).length).toEqual(1);
    expect(dynamodbMock.commandCalls(PutCommand)[0].args[0].input).toMatchObject({
      Item: {
        HasFileKeys: 1,
        FileKeys: JSON.stringify(attachmentS3AccessKeys),
      },
    });
  });

  it("includes the notification ID when provided", async () => {
    dynamodbMock.on(PutCommand).resolves({});

    const notificationId = "notification-id";

    await saveProcessableSubmissionToReliabilityStorage(submissionId, { ...submissionPayload, notificationId }).run();

    expect(dynamodbMock.commandCalls(PutCommand).length).toEqual(1);
    expect(dynamodbMock.commandCalls(PutCommand)[0].args[0].input).toMatchObject({
      Item: {
        NotificationID: notificationId,
      },
    });
  });

  it("maps the DynamoDB error to an Error", async () => {
    const dynamodbError = new Error("DynamoDB is unavailable");

    dynamodbMock.on(PutCommand).rejects(dynamodbError);

    const result = await saveProcessableSubmissionToReliabilityStorage(submissionId, submissionPayload).run();

    expect(result.extract()).toEqual(new Error("Failed to save processable submission to reliability storage", { cause: dynamodbError }));
  });
});

describe("attachSubmissionProcessingRequestIdToProcessableSubmission", () => {
  beforeAll(() => {
    vi.stubEnv("DYNAMODB_RELIABILITY_QUEUE_TABLE_NAME", "dynamodb_table_name");
  });

  afterEach(() => {
    dynamodbMock.reset();
  });

  it("updates the saved submission with the submission processing request ID", async () => {
    dynamodbMock.on(UpdateCommand).resolves({});

    const result = await attachSubmissionProcessingRequestIdToProcessableSubmission(submissionId, submissionProcessingRequestId).run();

    expect(result.extract()).toEqual(undefined);

    expect(dynamodbMock.commandCalls(UpdateCommand).length).toEqual(1);
    expect(dynamodbMock.commandCalls(UpdateCommand)[0].args[0].input).toEqual({
      TableName: process.env.DYNAMODB_RELIABILITY_QUEUE_TABLE_NAME,
      Key: {
        SubmissionID: "submission-id",
      },
      UpdateExpression: "SET SendReceipt = :receiptId",
      ExpressionAttributeValues: {
        ":receiptId": "submission-processing-request-id",
      },
    });
  });

  it("maps the DynamoDB error to an Error", async () => {
    const dynamodbError = new Error("DynamoDB is unavailable");

    dynamodbMock.on(UpdateCommand).rejects(dynamodbError);

    const result = await attachSubmissionProcessingRequestIdToProcessableSubmission(submissionId, submissionProcessingRequestId).run();

    expect(result.extract()).toEqual(new Error("Failed to attach submission processing request identifier to processable submission", { cause: dynamodbError }));
  });
});
