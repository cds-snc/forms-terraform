import type { PresignedPost } from "@aws-sdk/s3-presigned-post";
import type { Context } from "aws-lambda";
import { EitherAsyncUtils } from "common";
import { Just, Left, Nothing, Right } from "purify-ts";
import { type Version4Options, v4 } from "uuid";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { contextualLoggerMock } from "../../../vitest-setup.ts";
import { saveProcessableSubmission } from "../src/lib/processableSubmissionStore.ts";
import {
  type Attachment,
  type AttachmentWithS3UploadUrl,
  associateAttachmentWithCorrespondingChecksum,
  findAttachmentsInResponses,
  generateAttachmentS3AccessKeys,
  generateAttachmentUploadUrls,
} from "../src/lib/submissionAttachments.ts";
import { enqueueDelayedSubmissionProcessingRequest } from "../src/lib/submissionProcessingEnqueuer.ts";
import { handler } from "../src/main.ts";

vi.mock("uuid");
vi.mock("../src/lib/submissionAttachments.ts");
vi.mock("../src/lib/processableSubmissionStore.ts");
vi.mock("../src/lib/submissionProcessingEnqueuer.ts");

const uuidV4Mock = vi.mocked(v4 as (options?: Version4Options, buf?: undefined, offset?: number) => string);
const findAttachmentsInResponsesMock = vi.mocked(findAttachmentsInResponses);
const associateAttachmentWithCorrespondingChecksumMock = vi.mocked(associateAttachmentWithCorrespondingChecksum);
const generateAttachmentS3AccessKeysMock = vi.mocked(generateAttachmentS3AccessKeys);
const generateAttachmentUploadUrlsMock = vi.mocked(generateAttachmentUploadUrls);
const saveProcessableSubmissionMock = vi.mocked(saveProcessableSubmission);
const enqueueDelayedSubmissionProcessingRequestMock = vi.mocked(enqueueDelayedSubmissionProcessingRequest);

const SUBMISSION_ID = "submission-123";
const FORM_ID = "tz4a98xxat96iws9zmbrgj3a";
const SUBMISSION_PROCESSING_REQUEST_ID = "processing-request-123";

const defaultLambdaPayload = {
  formID: FORM_ID,
  language: "en",
  responses: {
    question1: "Answer 1",
    question2: "Answer 2",
  },
  securityAttribute: "Unclassified",
};

function invokeLambdaHandler(payload: unknown = defaultLambdaPayload): Promise<unknown> {
  return handler(payload, {} as Context);
}

describe("Submission Lambda", () => {
  beforeEach(() => {
    vi.resetAllMocks();

    uuidV4Mock.mockReturnValue(SUBMISSION_ID);
    findAttachmentsInResponsesMock.mockReturnValue(Nothing);
    saveProcessableSubmissionMock.mockImplementation(() => EitherAsyncUtils.rightVoid());
    enqueueDelayedSubmissionProcessingRequestMock.mockImplementation(() =>
      EitherAsyncUtils.right({
        submissionProcessingRequestId: SUBMISSION_PROCESSING_REQUEST_ID,
      }),
    );
  });

  describe("event validation", () => {
    it.each([defaultLambdaPayload])("accepts a valid payload (testing %s)", async (validPayload) => {
      await expect(invokeLambdaHandler(validPayload)).resolves.not.toThrow();
    });

    it.each([
      { formID: "not-a-cuid" },
      { language: "es" },
      { responses: undefined },
      { securityAttribute: "Secret" },
      { fileChecksums: { attachment: 123 } },
      { version: 0 },
      { version: -1 },
      { version: 1.5 },
      { notificationId: "invalid" },
    ])("rejects an invalid payload property (testing %s)", async (invalidProperty) => {
      await expect(
        invokeLambdaHandler({
          ...defaultLambdaPayload,
          ...invalidProperty,
        }),
      ).rejects.toThrow("Failed to validate lambda event");
    });

    it.each([{ fileChecksums: undefined }, { version: undefined }, { notificationId: undefined }])("accepts an omitted optional payload property (testing %s)", async (optionalProperty) => {
      await expect(
        invokeLambdaHandler({
          ...defaultLambdaPayload,
          ...optionalProperty,
        }),
      ).resolves.not.toThrow();
    });

    it.each(["en", "fr"] as const)("accepts valid language payload property value (testing %s)", async (language) => {
      await expect(invokeLambdaHandler({ ...defaultLambdaPayload, language })).resolves.not.toThrow();
    });

    it.each(["Unclassified", "Protected A", "Protected B"] as const)("accepts valid securityAttribute payload property value (testing %s)", async (securityAttribute) => {
      await expect(invokeLambdaHandler({ ...defaultLambdaPayload, securityAttribute })).resolves.not.toThrow();
    });
  });

  describe("submission configuration", () => {
    it("generates a submission ID", async () => {
      await invokeLambdaHandler();

      expect(uuidV4Mock).toHaveBeenCalledExactlyOnceWith();
    });

    it("adds the submission ID and form ID to the contextual logger metadata", async () => {
      await invokeLambdaHandler();

      expect(contextualLoggerMock.addMetadata).toHaveBeenCalledWith("submissionId", SUBMISSION_ID);
      expect(contextualLoggerMock.addMetadata).toHaveBeenCalledWith("formId", FORM_ID);
    });
  });

  describe("submissions without attachments", () => {
    it("saves the submission and enqueues a delayed processing request", async () => {
      await invokeLambdaHandler();

      expect(saveProcessableSubmissionMock).toHaveBeenCalledExactlyOnceWith({
        id: SUBMISSION_ID,
        associatedFormId: FORM_ID,
        language: "en",
        responses: defaultLambdaPayload.responses,
        securityAttribute: "Unclassified",
        version: 1,
        attachmentS3AccessKeys: undefined,
        notificationId: undefined,
      });

      expect(enqueueDelayedSubmissionProcessingRequestMock).toHaveBeenCalledExactlyOnceWith(SUBMISSION_ID);
    });

    it("uses the provided version and notification ID when saving the submission", async () => {
      const payload = {
        ...defaultLambdaPayload,
        version: 3,
        notificationId: "550e8400-e29b-41d4-a716-446655440000",
      };

      await invokeLambdaHandler(payload);

      expect(saveProcessableSubmissionMock).toHaveBeenCalledExactlyOnceWith({
        id: SUBMISSION_ID,
        associatedFormId: FORM_ID,
        language: "en",
        responses: defaultLambdaPayload.responses,
        securityAttribute: "Unclassified",
        version: 3,
        attachmentS3AccessKeys: undefined,
        notificationId: payload.notificationId,
      });
    });

    it("adds the submission processing request ID to the contextual logger metadata", async () => {
      await invokeLambdaHandler();

      expect(contextualLoggerMock.addMetadata).toHaveBeenCalledWith("submissionProcessingRequestId", SUBMISSION_PROCESSING_REQUEST_ID);
    });

    it("returns the submission ID", async () => {
      const result = await invokeLambdaHandler();

      expect(result).toEqual({
        submissionId: SUBMISSION_ID,
      });
    });

    it("logs a successful submission", async () => {
      await invokeLambdaHandler();

      expect(contextualLoggerMock.log).toHaveBeenCalledWith({
        level: "info",
        message: "Submission processed successfully",
      });
    });

    it("does not enqueue a processing request when saving a submission fails", async () => {
      const error = new Error("Failed to save submission");

      saveProcessableSubmissionMock.mockImplementationOnce(() => EitherAsyncUtils.left(error));

      await expect(invokeLambdaHandler()).rejects.toEqual(error);

      expect(saveProcessableSubmissionMock).toHaveBeenCalledExactlyOnceWith(expect.any(Object));
      expect(enqueueDelayedSubmissionProcessingRequestMock).not.toHaveBeenCalled();
    });

    it("logs an error when saving a submission fails", async () => {
      const error = new Error("Failed to save submission");

      saveProcessableSubmissionMock.mockImplementationOnce(() => EitherAsyncUtils.left(error));

      await expect(invokeLambdaHandler()).rejects.toEqual(error);

      expect(contextualLoggerMock.log).toHaveBeenCalledWith({
        level: "error",
        message: "Submission processing failed",
        error,
        severityLevel: "1",
      });
    });

    it("logs an error when enqueuing a delayed processing request fails", async () => {
      const error = new Error("Failed to enqueue submission processing request");

      enqueueDelayedSubmissionProcessingRequestMock.mockImplementationOnce(() => EitherAsyncUtils.left(error));

      await expect(invokeLambdaHandler()).rejects.toEqual(error);

      expect(contextualLoggerMock.log).toHaveBeenCalledWith({
        level: "error",
        message: "Submission processing failed",
        error,
        severityLevel: "1",
      });
    });
  });

  describe("submissions with attachments", () => {
    const attachment = {
      id: "attachment-1",
    } as Attachment;

    const attachmentWithChecksum = {
      id: "attachment-1",
      checksum: "content-md5-123",
    };

    const attachmentS3AccessKeys = [
      {
        id: "attachment-1",
        s3AccessKey: "s3-access-key-1",
      },
    ];

    const presignedPost = {
      url: "https://example.com/upload",
      fields: {
        key: "attachment-1",
      },
    } as PresignedPost;

    const attachmentS3UploadUrls = [
      {
        id: "attachment-1",
        s3AccessKey: "s3-access-key-1",
        s3UploadUrl: presignedPost,
      },
    ] as AttachmentWithS3UploadUrl[];

    const payloadWithAttachments = {
      ...defaultLambdaPayload,
      responses: {
        fileInput: ["attachment-1"],
      },
      fileChecksums: {
        "attachment-1": "content-md5-123",
      },
    };

    beforeEach(() => {
      findAttachmentsInResponsesMock.mockReturnValue(Just([attachment]));
      associateAttachmentWithCorrespondingChecksumMock.mockReturnValue(Right([attachmentWithChecksum] as never));
      generateAttachmentS3AccessKeysMock.mockReturnValue(attachmentS3AccessKeys as never);
      generateAttachmentUploadUrlsMock.mockImplementation(() => EitherAsyncUtils.right(attachmentS3UploadUrls));
    });

    it("associates attachments with their corresponding checksums", async () => {
      await invokeLambdaHandler(payloadWithAttachments);

      expect(associateAttachmentWithCorrespondingChecksumMock).toHaveBeenCalledExactlyOnceWith([attachment], payloadWithAttachments.fileChecksums);
    });

    it("generates S3 access keys for the attachments", async () => {
      await invokeLambdaHandler(payloadWithAttachments);

      expect(generateAttachmentS3AccessKeysMock).toHaveBeenCalledExactlyOnceWith(SUBMISSION_ID, [attachmentWithChecksum]);
    });

    it("adds attachment information to the contextual logger metadata", async () => {
      await invokeLambdaHandler(payloadWithAttachments);

      expect(contextualLoggerMock.addMetadata).toHaveBeenCalledWith("attachments", JSON.stringify([attachment]));
      expect(contextualLoggerMock.addMetadata).toHaveBeenCalledWith("attachments", JSON.stringify(attachmentS3AccessKeys));
    });

    it("generates attachment upload URLs", async () => {
      await invokeLambdaHandler(payloadWithAttachments);

      expect(generateAttachmentUploadUrlsMock).toHaveBeenCalledExactlyOnceWith(attachmentS3AccessKeys);
    });

    it("saves the submission with its attachment S3 access keys", async () => {
      await invokeLambdaHandler(payloadWithAttachments);

      expect(saveProcessableSubmissionMock).toHaveBeenCalledExactlyOnceWith({
        id: SUBMISSION_ID,
        associatedFormId: FORM_ID,
        language: "en",
        responses: payloadWithAttachments.responses,
        securityAttribute: "Unclassified",
        version: 1,
        attachmentS3AccessKeys: ["s3-access-key-1"],
        notificationId: undefined,
      });
    });

    it("returns the submission ID and attachment upload URLs", async () => {
      const result = await invokeLambdaHandler(payloadWithAttachments);

      expect(result).toEqual({
        submissionId: SUBMISSION_ID,
        fileURLMap: {
          "attachment-1": presignedPost,
        },
      });
    });

    it("does not enqueue a delayed processing request", async () => {
      await invokeLambdaHandler(payloadWithAttachments);

      expect(enqueueDelayedSubmissionProcessingRequestMock).not.toHaveBeenCalled();
    });

    it("logs a successful submission", async () => {
      await invokeLambdaHandler(payloadWithAttachments);

      expect(contextualLoggerMock.log).toHaveBeenCalledWith({
        level: "info",
        message: "Submission processed successfully",
      });
    });

    it("returns an error when no content MD5 checksums are provided", async () => {
      const { fileChecksums: _, ...payloadWithoutChecksums } = payloadWithAttachments;

      const error = new Error("Attachments have been detected in the responses but no content MD5 checksums were provided");

      await expect(invokeLambdaHandler(payloadWithoutChecksums)).rejects.toEqual(error);

      expect(associateAttachmentWithCorrespondingChecksumMock).not.toHaveBeenCalled();
      expect(generateAttachmentS3AccessKeysMock).not.toHaveBeenCalled();
      expect(generateAttachmentUploadUrlsMock).not.toHaveBeenCalled();
      expect(saveProcessableSubmissionMock).not.toHaveBeenCalled();
    });

    it("does not save the submission when checksum association fails", async () => {
      const error = new Error("Failed to associate attachment checksums");

      findAttachmentsInResponsesMock.mockReturnValue(Just([{ id: "attachment-1" } as Attachment]));

      associateAttachmentWithCorrespondingChecksumMock.mockReturnValue(Left(error));

      await expect(
        invokeLambdaHandler({
          ...defaultLambdaPayload,
          responses: { fileInput: ["attachment-1"] },
          fileChecksums: { "attachment-1": "content-md5-123" },
        }),
      ).rejects.toEqual(error);

      expect(generateAttachmentS3AccessKeysMock).not.toHaveBeenCalled();
      expect(generateAttachmentUploadUrlsMock).not.toHaveBeenCalled();
      expect(saveProcessableSubmissionMock).not.toHaveBeenCalled();
    });

    it("does not save the submission when generating attachment upload URLs fails", async () => {
      const error = new Error("Failed to generate attachment upload URLs");

      generateAttachmentUploadUrlsMock.mockImplementationOnce(() => EitherAsyncUtils.left(error));

      await expect(
        invokeLambdaHandler({
          ...defaultLambdaPayload,
          responses: { fileInput: ["attachment-1"] },
          fileChecksums: { "attachment-1": "content-md5-123" },
        }),
      ).rejects.toEqual(error);

      expect(saveProcessableSubmissionMock).not.toHaveBeenCalled();
    });

    it("logs an error when attachment processing fails", async () => {
      const error = new Error("Failed to generate attachment upload URLs");

      generateAttachmentUploadUrlsMock.mockImplementationOnce(() => EitherAsyncUtils.left(error));

      await expect(
        invokeLambdaHandler({
          ...defaultLambdaPayload,
          responses: { fileInput: ["attachment-1"] },
          fileChecksums: { "attachment-1": "content-md5-123" },
        }),
      ).rejects.toEqual(error);

      expect(contextualLoggerMock.log).toHaveBeenCalledWith({
        level: "error",
        message: "Submission processing failed",
        error,
        severityLevel: "1",
      });
    });
  });
});
