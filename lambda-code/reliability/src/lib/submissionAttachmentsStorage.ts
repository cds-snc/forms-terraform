import { CopyObjectCommand, DeleteObjectCommand, GetObjectCommand, type GetObjectCommandOutput, GetObjectTaggingCommand, HeadObjectCommand } from "@aws-sdk/client-s3";
import { EitherAsync, Just, Left, type Maybe, Nothing, Right } from "purify-ts";
import { s3Client } from "./awsServicesConnector.ts";

export function retrieveSubmissionAttachmentScanStatusFromTemporaryStorage(attachmentPath: string): EitherAsync<Error, string> {
  return EitherAsync(() =>
    s3Client.send(
      new GetObjectTaggingCommand({
        Bucket: process.env.S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME,
        Key: attachmentPath,
      }),
    ),
  )
    .map(({ TagSet }) => {
      if (TagSet === undefined) {
        throw new Error("TagSet is undefined");
      }

      const scanStatus = TagSet.find((tag) => tag.Key === "GuardDutyMalwareScanStatus")?.Value;

      if (scanStatus === undefined) {
        throw new Error("GuardDutyMalwareScanStatus tagset key does not exist");
      }

      return scanStatus;
    })
    .mapLeft((error) => new Error("Failed to retrieve submission attachment scan status from temporary storage", { cause: error }));
}

export function retrieveSubmissionAttachmentMd5ChecksumFromTemporaryStorage(attachmentPath: string): EitherAsync<Error, string> {
  return EitherAsync(() =>
    s3Client.send(
      new HeadObjectCommand({
        Bucket: process.env.S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME,
        Key: attachmentPath,
      }),
    ),
  )
    .map(({ Metadata }) => {
      if (Metadata === undefined) {
        throw new Error("Metadata is undefined");
      }

      if (Metadata.md5 === undefined) {
        throw new Error("md5 metadata key does not exist");
      }

      return Metadata.md5;
    })
    .mapLeft((error) => new Error("Failed to retrieve submission attachment MD5 checksum from temporary storage", { cause: error }));
}

export function copySubmissionAttachmentsFromTemporaryToPermanentStorage(attachmentPaths: string[]): EitherAsync<Error, void> {
  return EitherAsync.all(
    attachmentPaths.map((attachmentPath) => {
      const lastSlashIndex = attachmentPath.lastIndexOf("/");
      const attachmentPathMinusAttachmentName = attachmentPath.slice(0, lastSlashIndex);
      const attachmentName = attachmentPath.slice(lastSlashIndex + 1);

      return EitherAsync(() =>
        s3Client.send(
          new CopyObjectCommand({
            Bucket: process.env.S3_VAULT_FILE_STORAGE_BUCKET_NAME,
            CopySource: `${process.env.S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME}/${attachmentPathMinusAttachmentName}/${encodeURIComponent(attachmentName)}`,
            Key: attachmentPath,
          }),
        ),
      );
    }),
  )
    .void()
    .mapLeft((error) => new Error("Failed to copy submission attachments from temporary to permanent storage", { cause: error }));
}

export function deleteSubmissionAttachmentsFromTemporaryStorage(attachmentPaths: string[]): EitherAsync<Error, void> {
  return EitherAsync.all(
    attachmentPaths.map((attachmentPath) => {
      return EitherAsync(() =>
        s3Client.send(
          new DeleteObjectCommand({
            Bucket: process.env.S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME,
            Key: attachmentPath,
          }),
        ),
      );
    }),
  )
    .void()
    .mapLeft((error) => new Error("Failed to delete submission attachments from temporary storage", { cause: error }));
}

export function retrieveSubmissionAttachmentFirst100BytesFromTemporaryStorage(attachmentPath: string): EitherAsync<Error, Maybe<Uint8Array<ArrayBufferLike>>> {
  return EitherAsync<Error, GetObjectCommandOutput>(() =>
    s3Client.send(
      new GetObjectCommand({
        Bucket: process.env.S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME,
        Key: attachmentPath,
        Range: "bytes=0-99",
      }),
    ),
  )
    .chain(({ Body }) => {
      if (Body === undefined) {
        return EitherAsync.liftEither(Left(new Error("Body is undefined")));
      }

      return EitherAsync<Error, Uint8Array<ArrayBufferLike>>(() => Body.transformToByteArray());
    })
    .map((bytes) => {
      if (bytes.length < 100) {
        // Returns nothing since attachment is less than 100 bytes long
        return Nothing;
      }

      return Just(bytes);
    })
    .chainLeft((error) => {
      if (error.name === "InvalidRange") {
        // Returns nothing since attachment is empty
        return EitherAsync.liftEither(Right(Nothing));
      } else {
        return EitherAsync.liftEither(Left(new Error("Failed to retrieve submission attachment first 100 bytes from temporary storage", { cause: error })));
      }
    });
}
