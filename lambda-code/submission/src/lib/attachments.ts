import { S3Client } from "@aws-sdk/client-s3";
import { createPresignedPost, type PresignedPost } from "@aws-sdk/s3-presigned-post";
import { Either, EitherAsync } from "purify-ts";

export type Attachment = {
  id: string;
  name: string;
  size: number;
};

type AttachmentWithAssociatedChecksum = Attachment & {
  checksum: string;
};

type AttachmentWithS3AccessKey = AttachmentWithAssociatedChecksum & {
  s3AccessKey: string;
};

type AttachmentWithS3UploadUrl = AttachmentWithS3AccessKey & {
  s3UploadUrl: PresignedPost;
};

const S3_MAX_FILE_SIZE_ALLOWED_IN_BYTES = 10485760; // S3 signed URL allows users to upload file up to 10 MB
const S3_SIGNED_URL_LIFETIME_IN_SECONDS = 600; // S3 signed URL gives users 10 minutes to begin uploading a file

const s3Client = new S3Client({
  region: process.env.REGION ?? "ca-central-1",
});

export function searchForAttachmentsInResponses(responses: Record<string, unknown>): Either<never, Attachment[]> {
  function isAttachment(value: unknown): value is Attachment {
    if (value === null || typeof value !== "object" || Array.isArray(value)) {
      return false;
    }

    const object = value as Record<string, unknown>;

    return typeof object.id === "string" && typeof object.name === "string" && typeof object.size === "number";
  }

  function searchForAttachments(value: unknown): Attachment[] {
    if (isAttachment(value)) {
      return [value];
    }

    if (Array.isArray(value)) {
      return value.flatMap(searchForAttachments);
    }

    if (value !== null && typeof value === "object") {
      return Object.values(value).flatMap(searchForAttachments);
    }

    return [];
  }

  return Either.encase(() => searchForAttachments(responses));
}

export function associateAttachmentWithCorrespondingChecksum(attachments: Attachment[], attachmentChecksums: Record<string, string>): Either<Error, AttachmentWithAssociatedChecksum[]> {
  return Either.encase(() =>
    attachments.map((attachment) => {
      const checksum = attachmentChecksums[attachment.id];

      if (checksum === undefined) {
        throw new Error(`Could not find any content MD5 checksum associated to attachment ID: ${attachment.id}`);
      }

      return { ...attachment, checksum };
    }),
  );
}

export function generateAttachmentS3AccessKeys(submissionId: string, attachmentWithChecksums: AttachmentWithAssociatedChecksum[]): Either<never, AttachmentWithS3AccessKey[]> {
  const keyPrefix = `form_attachments/${new Date().toISOString().slice(0, 10)}/${submissionId}`;
  return Either.encase(() => attachmentWithChecksums.map((attachment) => ({ ...attachment, s3AccessKey: `${keyPrefix}/${attachment.id}/${attachment.name}` })));
}

export function generateAttachmentUploadUrls(attachmentWithS3AccessKeys: AttachmentWithS3AccessKey[]): EitherAsync<Error, AttachmentWithS3UploadUrl[]> {
  function generateS3UploadUrl(key: string, contentMd5Checksum: string): EitherAsync<Error, PresignedPost> {
    const base64ContentMd5 = Buffer.from(contentMd5Checksum, "hex").toString("base64");

    return EitherAsync(() => {
      return createPresignedPost(s3Client, {
        Bucket: process.env.S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME ?? "missing_bucket_name",
        Key: key,
        Fields: {
          acl: "bucket-owner-full-control",
          "x-amz-meta-md5": contentMd5Checksum,
          "Content-MD5": base64ContentMd5,
        },
        Conditions: [["content-length-range", 0, S3_MAX_FILE_SIZE_ALLOWED_IN_BYTES], { "Content-MD5": base64ContentMd5 }],
        Expires: S3_SIGNED_URL_LIFETIME_IN_SECONDS,
      }).catch((error: unknown) => {
        throw new Error(`Failed to generate S3 upload URL for ${key}`, {
          cause: error,
        });
      });
    });
  }

  return EitherAsync.all(
    attachmentWithS3AccessKeys.map((attachment) =>
      generateS3UploadUrl(attachment.s3AccessKey, attachment.checksum).map((s3UploadUrl) => {
        return { ...attachment, s3UploadUrl };
      }),
    ),
  ).mapLeft((error) => {
    throw new Error("Failed to generate attachment upload URLs", {
      cause: error,
    });
  });
}
