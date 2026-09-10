import { createPresignedPost } from "@aws-sdk/s3-presigned-post";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { associateAttachmentWithCorrespondingChecksum, generateAttachmentS3AccessKeys, generateAttachmentUploadUrls, searchForAttachmentsInResponses } from "../../src/lib/attachments.ts";
import { searchForAttachmentsInResponsesTestData } from "./attachment.testdata.ts";

vi.mock("@aws-sdk/s3-presigned-post", () => ({
  createPresignedPost: vi.fn(),
}));

const createPresignedPostMock = vi.mocked(createPresignedPost);

describe("searchForAttachmentsInResponses", () => {
  it.each(searchForAttachmentsInResponsesTestData)("finds all attachments in response: $responses", ({ responses, expectedAttachments }) => {
    expect(searchForAttachmentsInResponses(responses).extract()).toEqual(expectedAttachments); // TODO: add new test data
  });
});

describe("associateAttachmentWithCorrespondingChecksum", () => {
  it("associates the corresponding checksum with attachments", () => {
    const attachments = [
      {
        id: "attachment-1",
        name: "document.pdf",
        size: 1234,
      },
      {
        id: "attachment-2",
        name: "image.png",
        size: 5678,
      },
    ];

    const attachmentChecksums = {
      "attachment-1": "0123456789abcdef0123456789abcdef",
      "attachment-2": "abcdef0123456789abcdef0123456789",
    };

    const result = associateAttachmentWithCorrespondingChecksum(attachments, attachmentChecksums);

    expect(result.extract()).toEqual([
      {
        id: "attachment-1",
        name: "document.pdf",
        size: 1234,
        checksum: "0123456789abcdef0123456789abcdef",
      },
      {
        id: "attachment-2",
        name: "image.png",
        size: 5678,
        checksum: "abcdef0123456789abcdef0123456789",
      },
    ]);
  });

  it("returns an error when an attachment has no corresponding checksum", () => {
    const attachments = [
      {
        id: "attachment-1",
        name: "document.pdf",
        size: 1234,
      },
    ];

    const result = associateAttachmentWithCorrespondingChecksum(attachments, {});

    expect(result.extract()).toEqual(new Error("Could not find any content MD5 checksum associated to attachment ID: attachment-1"));
  });

  it("returns an error when one of multiple attachments has no corresponding checksum", () => {
    const attachments = [
      {
        id: "attachment-1",
        name: "document.pdf",
        size: 1234,
      },
      {
        id: "attachment-2",
        name: "image.png",
        size: 5678,
      },
    ];

    const result = associateAttachmentWithCorrespondingChecksum(attachments, {
      "attachment-1": "0123456789abcdef0123456789abcdef",
    });

    expect(result.extract()).toEqual(new Error("Could not find any content MD5 checksum associated to attachment ID: attachment-2"));
  });
});

describe("generateAttachmentS3AccessKeys", () => {
  it("generate S3 access keys for attachments", () => {
    vi.setSystemTime(new Date("2026-08-08T08:08:08.888Z"));

    const attachments = [
      {
        id: "attachment-1",
        name: "document.pdf",
        size: 1234,
        checksum: "checksum",
      },
      {
        id: "attachment-2",
        name: "image.png",
        size: 5678,
        checksum: "",
      },
    ];

    const result = generateAttachmentS3AccessKeys("submission-123", attachments);

    expect(result.extract()).toEqual([
      {
        ...attachments[0],
        s3AccessKey: "form_attachments/2026-08-08/submission-123/attachment-1/document.pdf",
      },
      {
        ...attachments[1],
        s3AccessKey: "form_attachments/2026-08-08/submission-123/attachment-2/image.png",
      },
    ]);
  });
});

describe("generateAttachmentUploadUrls", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("generates upload URLs for attachments", async () => {
    const attachments = [
      {
        id: "attachment-1",
        name: "document.pdf",
        size: 1234,
        checksum: "checksum-1",
        s3AccessKey: "key-1",
      },
      {
        id: "attachment-2",
        name: "image.png",
        size: 5678,
        checksum: "checksum-2",
        s3AccessKey: "key-2",
      },
    ];

    const uploadUrl1 = {
      url: "https://example.com/upload/1",
      fields: {},
    };

    const uploadUrl2 = { url: "https://example.com/upload/2", fields: {} };

    createPresignedPostMock.mockResolvedValueOnce(uploadUrl1).mockResolvedValueOnce(uploadUrl2);

    const result = await generateAttachmentUploadUrls(attachments).run();

    expect(result.extract()).toEqual([
      {
        ...attachments[0],
        s3UploadUrl: uploadUrl1,
      },
      {
        ...attachments[1],
        s3UploadUrl: uploadUrl2,
      },
    ]);

    expect(createPresignedPostMock).toHaveBeenCalledTimes(2);
  });

  it("returns an error when generating an S3 upload URL fails", async () => {
    const attachment = {
      id: "attachment-1",
      name: "document.pdf",
      size: 1234,
      checksum: "checksum",
      s3AccessKey: "some/key",
    };

    const s3Error = new Error("S3 signing failed");

    createPresignedPostMock.mockRejectedValue(s3Error);

    const result = await generateAttachmentUploadUrls([attachment]).run();

    expect(result.extract()).toEqual(
      new Error("Failed to generate attachment upload URLs", {
        cause: new Error("Failed to generate S3 upload URL for some/key", {
          cause: s3Error,
        }),
      }),
    );
  });
});
