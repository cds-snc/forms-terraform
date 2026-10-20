import type { PresignedPost } from "@aws-sdk/s3-presigned-post";
import type { Context } from "aws-lambda";
import { EitherAsync, Left, Right } from "purify-ts";
import { type Version4Options, v4 } from "uuid";
import { beforeEach, describe, expect, it, vi } from "vitest";
import {
  type Attachment,
  associateAttachmentWithCorrespondingChecksum,
  generateAttachmentS3AccessKeys,
  generateAttachmentUploadUrls,
  searchForAttachmentsInResponses,
} from "../src/lib/attachments.ts";
import { extractSubmissionPayloadFromLambdaEvent } from "../src/lib/payload.ts";
import { enqueueDelayedSubmissionProcessingRequest } from "../src/lib/processing.ts";
import { attachSubmissionProcessingRequestIdToSavedSubmission, saveSubmissionToReliabilityStorage } from "../src/lib/storage.ts";
import { handler } from "../src/main.ts";

vi.mock("uuid");
vi.mock("../src/lib/payload.ts");
vi.mock("../src/lib/attachments.ts");
vi.mock("../src/lib/processing.ts");
vi.mock("../src/lib/storage.ts");

const uuidV4Mock = vi.mocked(v4 as (options?: Version4Options, buf?: undefined, offset?: number) => string);
const extractSubmissionPayloadFromLambdaEventMock = vi.mocked(extractSubmissionPayloadFromLambdaEvent);
const searchForAttachmentsInResponsesMock = vi.mocked(searchForAttachmentsInResponses);
const associateAttachmentWithCorrespondingChecksumMock = vi.mocked(associateAttachmentWithCorrespondingChecksum);
const generateAttachmentS3AccessKeysMock = vi.mocked(generateAttachmentS3AccessKeys);
const generateAttachmentUploadUrlsMock = vi.mocked(generateAttachmentUploadUrls);
const enqueueDelayedSubmissionProcessingRequestMock = vi.mocked(enqueueDelayedSubmissionProcessingRequest);
const saveSubmissionToReliabilityStorageMock = vi.mocked(saveSubmissionToReliabilityStorage);
const attachSubmissionProcessingRequestIdToSavedSubmissionMock = vi.mocked(attachSubmissionProcessingRequestIdToSavedSubmission);

const submissionId = "submission-123";

const submissionPayload = {
  formID: "form-123",
  language: "en",
  responses: {
    name: "John Doe",
  },
  securityAttribute: "Unclassified",
};

const submissionPayloadWithAttachments = {
  ...submissionPayload,
  responses: {
    document: {
      id: "attachment-1",
      name: "document.pdf",
      size: 1234,
    },
  },
  fileChecksums: {
    "attachment-1": "0123456789abcdef0123456789abcdef",
  },
};

const attachment: Attachment = {
  id: "attachment-1",
  name: "document.pdf",
  size: 1234,
};

const attachmentWithChecksum = {
  ...attachment,
  checksum: "0123456789abcdef0123456789abcdef",
};

const attachmentWithS3AccessKey = {
  ...attachmentWithChecksum,
  s3AccessKey: "form_attachments/2026-09-10/submission-123/attachment-1/document.pdf",
};

const presignedPost: PresignedPost = {
  url: "https://example.com/upload",
  fields: {
    key: attachmentWithS3AccessKey.s3AccessKey,
  },
};

const attachmentWithS3UploadUrl = {
  ...attachmentWithS3AccessKey,
  s3UploadUrl: presignedPost,
};

function eitherAsyncRight<T>(value: T): EitherAsync<Error, T> {
  return EitherAsync.liftEither(Right(value));
}

function eitherAsyncLeft<T = never>(error: Error): EitherAsync<Error, T> {
  return EitherAsync.liftEither(Left(error));
}

function invokeLambdaHandler() {
  return handler({}, {} as Context);
}

describe("handler", () => {
  beforeEach(() => {
    vi.resetAllMocks();

    uuidV4Mock.mockReturnValue(submissionId);
    extractSubmissionPayloadFromLambdaEventMock.mockReturnValue(Right(submissionPayload));
    searchForAttachmentsInResponsesMock.mockReturnValue(Right([]));
    saveSubmissionToReliabilityStorageMock.mockReturnValue(eitherAsyncRight(undefined));
    enqueueDelayedSubmissionProcessingRequestMock.mockReturnValue(
      eitherAsyncRight({
        submissionProcessingRequestId: "processing-123",
      }),
    );
    attachSubmissionProcessingRequestIdToSavedSubmissionMock.mockReturnValue(eitherAsyncRight(undefined));
  });

  describe("submissions without attachments", () => {
    it("processes the submission successfully", async () => {
      await expect(invokeLambdaHandler()).resolves.toEqual({ submissionId });

      expect(saveSubmissionToReliabilityStorageMock).toHaveBeenCalledWith(submissionId, submissionPayload);
      expect(enqueueDelayedSubmissionProcessingRequestMock).toHaveBeenCalledWith(submissionId, 5);
      expect(attachSubmissionProcessingRequestIdToSavedSubmissionMock).toHaveBeenCalledWith(submissionId, "processing-123");
    });

    it("does not enqueue processing when saving the submission fails", async () => {
      const error = new Error("Failed to save submission");
      saveSubmissionToReliabilityStorageMock.mockReturnValue(eitherAsyncLeft(error));

      await expect(invokeLambdaHandler()).rejects.toEqual(error);

      expect(enqueueDelayedSubmissionProcessingRequestMock).not.toHaveBeenCalled();
      expect(attachSubmissionProcessingRequestIdToSavedSubmissionMock).not.toHaveBeenCalled();
    });

    it("does not attach the processing request ID when enqueueing fails", async () => {
      const error = new Error("Failed to enqueue processing request");
      enqueueDelayedSubmissionProcessingRequestMock.mockReturnValue(eitherAsyncLeft(error));

      await expect(invokeLambdaHandler()).rejects.toEqual(error);

      expect(attachSubmissionProcessingRequestIdToSavedSubmissionMock).not.toHaveBeenCalled();
    });

    it("returns an error when attaching the processing request ID fails", async () => {
      const error = new Error("Failed to attach processing request ID");

      attachSubmissionProcessingRequestIdToSavedSubmissionMock.mockReturnValue(eitherAsyncLeft(error));

      await expect(invokeLambdaHandler()).rejects.toEqual(error);
    });
  });

  describe("submissions with attachments", () => {
    beforeEach(() => {
      extractSubmissionPayloadFromLambdaEventMock.mockReturnValue(Right(submissionPayloadWithAttachments));
      searchForAttachmentsInResponsesMock.mockReturnValue(Right([attachment]));
      associateAttachmentWithCorrespondingChecksumMock.mockReturnValue(Right([attachmentWithChecksum]));
      generateAttachmentS3AccessKeysMock.mockReturnValue(Right([attachmentWithS3AccessKey]));
      generateAttachmentUploadUrlsMock.mockReturnValue(eitherAsyncRight([attachmentWithS3UploadUrl]));
    });

    it("processes the submission successfully", async () => {
      await expect(invokeLambdaHandler()).resolves.toEqual({
        submissionId,
        fileURLMap: {
          "attachment-1": presignedPost,
        },
      });

      expect(associateAttachmentWithCorrespondingChecksumMock).toHaveBeenCalledWith([attachment], submissionPayloadWithAttachments.fileChecksums);
      expect(generateAttachmentS3AccessKeysMock).toHaveBeenCalledWith(submissionId, [attachmentWithChecksum]);
      expect(generateAttachmentUploadUrlsMock).toHaveBeenCalledWith([attachmentWithS3AccessKey]);
      expect(saveSubmissionToReliabilityStorageMock).toHaveBeenCalledWith(submissionId, submissionPayloadWithAttachments, [attachmentWithS3AccessKey.s3AccessKey]);
      expect(enqueueDelayedSubmissionProcessingRequestMock).not.toHaveBeenCalled();
      expect(attachSubmissionProcessingRequestIdToSavedSubmissionMock).not.toHaveBeenCalled();
    });

    it("returns an error when checksums are missing", async () => {
      extractSubmissionPayloadFromLambdaEventMock.mockReturnValue(
        Right({
          ...submissionPayload,
          responses: {
            document: {
              id: "attachment-1",
              name: "document.pdf",
              size: 1234,
            },
          },
        }),
      );

      await expect(invokeLambdaHandler()).rejects.toEqual(new Error("Attachments have been detected in the responses but no content MD5 checksums were provided"));

      expect(associateAttachmentWithCorrespondingChecksumMock).not.toHaveBeenCalled();
      expect(generateAttachmentS3AccessKeysMock).not.toHaveBeenCalled();
      expect(generateAttachmentUploadUrlsMock).not.toHaveBeenCalled();
      expect(saveSubmissionToReliabilityStorageMock).not.toHaveBeenCalled();
    });

    it("returns an error when checksum association fails", async () => {
      const error = new Error("Missing checksum");
      associateAttachmentWithCorrespondingChecksumMock.mockReturnValue(Left(error));

      await expect(invokeLambdaHandler()).rejects.toEqual(error);

      expect(generateAttachmentS3AccessKeysMock).not.toHaveBeenCalled();
      expect(generateAttachmentUploadUrlsMock).not.toHaveBeenCalled();
      expect(saveSubmissionToReliabilityStorageMock).not.toHaveBeenCalled();
    });

    it("returns an error when generating S3 access keys fails", async () => {
      const error = new Error("Failed to generate S3 access keys");
      generateAttachmentS3AccessKeysMock.mockImplementation(() => {
        throw error;
      });

      await expect(invokeLambdaHandler()).rejects.toEqual(error);

      expect(generateAttachmentUploadUrlsMock).not.toHaveBeenCalled();
      expect(saveSubmissionToReliabilityStorageMock).not.toHaveBeenCalled();
    });

    it("returns an error when generating upload URLs fails", async () => {
      const error = new Error("Failed to generate upload URLs");
      generateAttachmentUploadUrlsMock.mockReturnValue(eitherAsyncLeft(error));

      await expect(invokeLambdaHandler()).rejects.toEqual(error);

      expect(saveSubmissionToReliabilityStorageMock).not.toHaveBeenCalled();
    });

    it("returns an error when saving the submission fails", async () => {
      const error = new Error("Failed to save submission");
      saveSubmissionToReliabilityStorageMock.mockReturnValue(eitherAsyncLeft(error));

      await expect(invokeLambdaHandler()).rejects.toEqual(error);
    });

    it("passes all attachment S3 access keys to submission storage", async () => {
      const secondAttachment: Attachment = {
        id: "attachment-2",
        name: "image.png",
        size: 5678,
      };

      const secondAttachmentWithChecksum = {
        ...secondAttachment,
        checksum: "abcdef0123456789abcdef0123456789",
      };

      const secondAttachmentWithS3AccessKey = {
        ...secondAttachmentWithChecksum,
        s3AccessKey: "form_attachments/2026-09-10/submission-123/attachment-2/image.png",
      };

      searchForAttachmentsInResponsesMock.mockReturnValue(Right([attachment, secondAttachment]));
      associateAttachmentWithCorrespondingChecksumMock.mockReturnValue(Right([attachmentWithChecksum, secondAttachmentWithChecksum]));
      generateAttachmentS3AccessKeysMock.mockReturnValue(Right([attachmentWithS3AccessKey, secondAttachmentWithS3AccessKey]));
      generateAttachmentUploadUrlsMock.mockReturnValue(
        eitherAsyncRight([
          attachmentWithS3UploadUrl,
          {
            ...secondAttachmentWithS3AccessKey,
            s3UploadUrl: presignedPost,
          },
        ]),
      );

      await invokeLambdaHandler();

      expect(saveSubmissionToReliabilityStorageMock).toHaveBeenCalledWith(submissionId, submissionPayloadWithAttachments, [
        attachmentWithS3AccessKey.s3AccessKey,
        secondAttachmentWithS3AccessKey.s3AccessKey,
      ]);
    });
  });

  describe("payload validation", () => {
    it("returns an error when the submission payload is invalid", async () => {
      const error = new Error("Invalid payload");
      extractSubmissionPayloadFromLambdaEventMock.mockReturnValue(Left(error));

      await expect(invokeLambdaHandler()).rejects.toEqual(error);

      expect(searchForAttachmentsInResponsesMock).not.toHaveBeenCalled();
      expect(saveSubmissionToReliabilityStorageMock).not.toHaveBeenCalled();
      expect(enqueueDelayedSubmissionProcessingRequestMock).not.toHaveBeenCalled();
    });
  });

  describe("submission ID", () => {
    it("uses the generated submission ID for downstream operations", async () => {
      uuidV4Mock.mockReturnValue("generated-submission-id");

      await invokeLambdaHandler();

      expect(saveSubmissionToReliabilityStorageMock).toHaveBeenCalledWith("generated-submission-id", submissionPayload);
      expect(enqueueDelayedSubmissionProcessingRequestMock).toHaveBeenCalledWith("generated-submission-id", 5);
      expect(attachSubmissionProcessingRequestIdToSavedSubmissionMock).toHaveBeenCalledWith("generated-submission-id", "processing-123");
    });
  });
});
