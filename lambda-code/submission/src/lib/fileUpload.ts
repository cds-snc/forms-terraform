import { S3Client } from "@aws-sdk/client-s3";
import { createPresignedPost, PresignedPost } from "@aws-sdk/s3-presigned-post";

export type FileReference = {
  id: string;
  name: string;
};

const S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME = process.env.S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME;

if (!S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME) {
  console.error(
    JSON.stringify({
      level: "warn",
      severity: 3,
      status: "failed",
      msg: "Submission lambda does not have environment variable for Reliability File Storage S3 bucket name",
    })
  );

  throw new Error("Missing environment variable for S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME");
}

const S3_MAX_FILE_SIZE_ALLOWED_IN_BYTES = 10485760; // S3 signed URL allows users to upload file up to 10 MB
const S3_SIGNED_URL_LIFETIME_IN_SECONDS = 600; // S3 signed URL gives users 10 minutes to begin uploading a file

const s3Client = new S3Client({
  region: process.env.REGION ?? "ca-central-1",
});

interface FileInput {
  id: string;
  name: string;
  size: number;
}

export function findAttachedFileReferencesInSubmissionResponses(
  responses: Record<string, unknown>,
  submissionId: string
): FileReference[] {
  const fileInputs = extractFileInputs(responses);

  // Log and transform
  return fileInputs.map((f) => {
    console.log(
      JSON.stringify({
        level: "info",
        msg: `File input detected for submission ${submissionId}: fileID=${f.id}, fileSize=${f.size} bytes.`,
      })
    );
    return { id: f.id, name: f.name };
  });
}

export async function generateFileAccessKeysAndUploadURLs(
  submissionId: string,
  fileReferences: FileReference[],
  fileChecksums?: Record<string, string>
): Promise<{ fileAccessKeys: string[]; fileUploadURLs: Record<string, PresignedPost> }> {
  const keyStartingPath = `form_attachments/${new Date()
    .toISOString()
    .slice(0, 10)}/${submissionId}`;

  const generateFileAccessKeyAndUploadURLOperationResults = await Promise.all(
    fileReferences.map(async (fileReference) => {
      const fileAccessKey = `${keyStartingPath}/${fileReference.id}/${fileReference.name}`;
      const contentMD5 = fileChecksums?.[fileReference.id];

      if (!contentMD5) {
        throw new Error(
          `Failed to generate signed URL. Reason: No checksum provided for file ID ${fileReference.id} in submission ${submissionId}.`
        );
      }

      const fileUploadURL = await generateSignedUrl(fileAccessKey, contentMD5);
      return { id: fileReference.id, fileAccessKey, fileUploadURL };
    })
  );

  return {
    fileAccessKeys: generateFileAccessKeyAndUploadURLOperationResults.map((r) => r.fileAccessKey),
    fileUploadURLs: generateFileAccessKeyAndUploadURLOperationResults.reduce((acc, current) => {
      acc[current.id] = current.fileUploadURL;
      return acc;
    }, {} as Record<string, PresignedPost>),
  };
}

const isFileInput = (response: unknown): response is FileInput => {
  return (
    response !== null &&
    typeof response === "object" &&
    "name" in response &&
    "size" in response &&
    "id" in response &&
    response.name !== null &&
    response.size !== null &&
    response.id !== null
  );
};

const extractFileInputs = (originalObject: Record<string, unknown>) => {
  const fileInputList: Array<FileInput> = [];

  const extractorLogic = (newObject: unknown, fileInputCollector: Array<FileInput>) => {
    // If it's not an {}, or [] stop now
    if (newObject === null || typeof newObject !== "object") return;

    // If it's a File Input object add it to the list and return
    if (isFileInput(newObject)) {
      return fileInputCollector.push(newObject);
    }

    // If it's an {} or [] keep going down the rabbit hole
    for (const obj of Array.isArray(newObject) ? newObject : Object.entries(newObject)) {
      extractorLogic(obj, fileInputCollector);
    }
  };

  // Let the recursive logic aka snake eating tail begin
  extractorLogic(originalObject, fileInputList);

  return fileInputList;
};

const generateSignedUrl = async (key: string, contentMD5?: string) => {
  const fields: Record<string, string> = {
    acl: "bucket-owner-full-control",
  };

  // Add Content-MD5 if provided
  if (contentMD5) {
    fields["Content-MD5"] = contentMD5;
  }

  let conditions = [["content-length-range", 0, S3_MAX_FILE_SIZE_ALLOWED_IN_BYTES]];

  if (contentMD5) {
    conditions = [
      ["content-length-range", 0, S3_MAX_FILE_SIZE_ALLOWED_IN_BYTES],
      ["eq", "$Content-MD5", contentMD5],
    ];
  }

  return createPresignedPost(s3Client, {
    Bucket: S3_RELIABILITY_FILE_STORAGE_BUCKET_NAME,
    Key: key,
    Fields: fields,
    Conditions: conditions,
    Expires: S3_SIGNED_URL_LIFETIME_IN_SECONDS,
  }).catch((error: unknown) => {
    throw new Error(`Failed to generate signed URL. Reason: ${(error as Error).message}.`);
  });
};
