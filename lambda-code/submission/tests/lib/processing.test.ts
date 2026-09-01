import { SendMessageCommand, SQSClient } from "@aws-sdk/client-sqs";
import { mockClient } from "aws-sdk-client-mock";
import { beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { enqueueDelayedSubmissionProcessingRequest } from "../../src/lib/processing.ts";

const sqsMock = mockClient(SQSClient);

describe("enqueueDelayedSubmissionProcessingRequest", () => {
  beforeAll(() => {
    vi.stubEnv("SQS_URL", "sqs_queue_name");
  });

  beforeEach(() => {
    sqsMock.reset();
  });

  it("sends a delayed submission processing request to SQS", async () => {
    sqsMock.on(SendMessageCommand).resolves({
      MessageId: "message-123",
    });

    await enqueueDelayedSubmissionProcessingRequest("submission-123", 5).run();

    expect(sqsMock.commandCalls(SendMessageCommand).length).toEqual(1);
    expect(sqsMock.commandCalls(SendMessageCommand)[0].args[0].input).toEqual({
      MessageBody: JSON.stringify({
        submissionID: "submission-123",
      }),
      DelaySeconds: 5,
      QueueUrl: process.env.SQS_URL,
    });
  });

  it("returns the submission processing request ID", async () => {
    sqsMock.on(SendMessageCommand).resolves({
      MessageId: "message-123",
    });

    const result = await enqueueDelayedSubmissionProcessingRequest("submission-123", 5).run();

    expect(result.extract()).toEqual({
      submissionProcessingRequestId: "message-123",
    });
  });

  it("returns an error when SQS does not return a message ID", async () => {
    sqsMock.on(SendMessageCommand).resolves({});

    const result = await enqueueDelayedSubmissionProcessingRequest("submission-123", 5).run();

    expect(result.extract()).toEqual(new Error("Failed to enqueue submission processing request", { cause: new Error("MessageId is undefined") }));
  });

  it("returns an error when SQS fails", async () => {
    const sqsError = new Error("SQS is unavailable");

    sqsMock.on(SendMessageCommand).rejects(sqsError);

    const result = await enqueueDelayedSubmissionProcessingRequest("submission-123", 5).run();

    expect(result.extract()).toEqual(new Error("Failed to enqueue submission processing request", { cause: sqsError }));
  });
});
