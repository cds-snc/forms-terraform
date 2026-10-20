import { GetObjectTaggingCommand, type GetObjectTaggingCommandOutput, HeadObjectCommand, type HeadObjectCommandOutput } from "@aws-sdk/client-s3";
import { EitherAsync } from "purify-ts";
import { s3Client } from "./awsServicesConnector.ts";

export function retrieveSubmissionAttachmentScanStatus(attachmentPath: string): EitherAsync<Error, string> {
  return EitherAsync<Error, GetObjectTaggingCommandOutput>(() =>
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
    .mapLeft((error) => new Error("Failed to retrieve submission attachment scan status", { cause: error }));
}

export function retrieveSubmissionAttachmentMd5Checksum(attachmentPath: string): EitherAsync<Error, string> {
  return EitherAsync<Error, HeadObjectCommandOutput>(() =>
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
    .mapLeft((error) => new Error("Failed to retrieve submission attachment MD5 checksum", { cause: error }));
}
