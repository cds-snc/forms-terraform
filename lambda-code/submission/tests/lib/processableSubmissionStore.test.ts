import { DynamoDBDocument, PutCommand } from "@aws-sdk/lib-dynamodb";
import { mockClient } from "aws-sdk-client-mock";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import { type ProcessableSubmission, saveProcessableSubmission } from "../../src/lib/processableSubmissionStore.ts";

const dynamodbMock = mockClient(DynamoDBDocument);

const processableSubmission: ProcessableSubmission = {
  id: "submissionId",
  associatedFormId: "associatedFormId",
  language: "en",
  securityAttribute: "Unclassified",
  version: 3,
  responses: { 1: "firstResponse", 2: "secondResponse" },
};

describe("saveProcessableSubmission", () => {
  beforeAll(() => {
    vi.stubEnv("DYNAMODB_RELIABILITY_QUEUE_TABLE_NAME", "dynamodb_table_name");
    vi.setSystemTime(new Date("2026-08-08T08:08:08.888Z"));
  });

  afterEach(() => {
    dynamodbMock.reset();
  });

  it("saves the submission to reliability storage", async () => {
    dynamodbMock.on(PutCommand).resolves({});

    await saveProcessableSubmission(processableSubmission).run();

    expect(dynamodbMock.commandCalls(PutCommand).length).toEqual(1);
    expect(dynamodbMock.commandCalls(PutCommand)[0].args[0].input).toEqual({
      TableName: process.env.DYNAMODB_RELIABILITY_QUEUE_TABLE_NAME,
      Item: {
        SubmissionID: processableSubmission.id,
        FormID: processableSubmission.associatedFormId,
        SendReceipt: "unknown",
        FormSubmissionLanguage: processableSubmission.language,
        FormData: JSON.stringify({ responses: processableSubmission.responses }),
        CreatedAt: 1786176488888,
        SecurityAttribute: processableSubmission.securityAttribute,
        Version: processableSubmission.version,
        FormSubmissionHash: "c2225caf1d91bddb29f4a1bc10db474a",
        HasFileKeys: 0,
      },
    });
  });

  it("includes attachment S3 access keys when provided", async () => {
    dynamodbMock.on(PutCommand).resolves({});

    const attachmentS3AccessKeys = ["attachment-key-1", "attachment-key-2"];

    await saveProcessableSubmission({ ...processableSubmission, attachmentS3AccessKeys }).run();

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

    await saveProcessableSubmission({ ...processableSubmission, notificationId }).run();

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

    const result = await saveProcessableSubmission(processableSubmission).run();

    expect(result.extract()).toEqual(new Error("Failed to save processable submission", { cause: dynamodbError }));
  });
});
