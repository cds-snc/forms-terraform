import { S3Client } from "@aws-sdk/client-s3";
import { createPresignedPost, PresignedPost } from "@aws-sdk/s3-presigned-post";

const bucketName: string = `forms-${process.env.ENVIRONMENT}-reliability-file-storage`;

const s3Client = new S3Client({
  region: process.env.REGION ?? "ca-central-1",
});

interface FileInput {
  id: string;
  name: string;
  size: number;
  key?: string;
}

/**
 *
 * @param fileName File name to generate signed URL for
 * @description Generates a signed URL for uploading a file to S3.
 * @returns Signed URL
 */

export const generateSignedUrl = async (key: string) => {
  const presigned = await createPresignedPost(s3Client, {
    Bucket: bucketName,
    Key: key,
    Fields: {
      acl: "bucket-owner-full-control",
    },
    Conditions: [
      ["content-length-range", 0, 10485760], // 10 MB max file size
    ],
    Expires: 600, // URL expires in 10 minutes
  });
  return presigned;
};

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

export const fileReferenceExtractor = (originalObj: unknown) => {
  const fileInputRefList: Array<FileInput> = [];

  const extractorLogic = (originalObj: unknown, fileObjs: Array<FileInput>) => {
    // If it's not an {}, or [] stop now
    if (originalObj === null || typeof originalObj !== "object") return;

    // If it's a File Input object add it to the list and return
    if (isFileInput(originalObj)) {
      return fileObjs.push(originalObj);
    }

    // If it's an {} or [] keep going down the rabbit hole
    for (const obj of Array.isArray(originalObj) ? originalObj : Object.entries(originalObj)) {
      extractorLogic(obj, fileObjs);
    }
  };
  // Let the recursive logic aka snake eating tail begin
  extractorLogic(originalObj, fileInputRefList);

  return fileInputRefList;
};

export const generateFileURLs = async (submissionId: string, submission: Record<string, any>) => {
  const fileRefs = fileReferenceExtractor(submission.responses);
  const pathKey = `form_attachments/${new Date().toISOString().slice(0, 10)}/${submissionId}`;
  const fileURLMap: Record<string, PresignedPost> = {};
  const fileKeys: string[] = [];

  for (const fileRef of fileRefs) {
    const fileKey = `${pathKey}/${fileRef.id}/${fileRef.name}`;

    fileRef.key = fileKey; // Add the key to the file reference

    fileURLMap[fileRef.id] = await generateSignedUrl(fileKey);
    fileKeys.push(fileKey); // Collect the file keys
  }
  console.info(
    `Generated ${Object.keys(fileRefs).length} signed urls for submission ${submissionId} `
  );
  return { fileKeys, fileURLMap };
};
