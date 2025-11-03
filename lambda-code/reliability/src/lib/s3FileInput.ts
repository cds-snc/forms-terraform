import {
  S3Client,
  GetObjectCommand,
  GetObjectTaggingCommand,
  CopyObjectCommand,
  DeleteObjectCommand,
  HeadObjectCommand,
} from "@aws-sdk/client-s3";
import { NodeJsClient } from "@smithy/types";

const s3Client = new S3Client({
  region: process.env.REGION ?? "ca-central-1",
  forcePathStyle: true,
}) as NodeJsClient<S3Client>;

const environment = process.env.ENVIRONMENT;
const reliabilityBucketName = `forms-${environment}-reliability-file-storage`;
const vaultBucketName = `forms-${environment}-vault-file-storage`;

async function getObject(bucket: string, key: string) {
  const getObjectCommand = new GetObjectCommand({
    Bucket: bucket,
    Key: key,
  });
  const response = await s3Client.send(getObjectCommand);

  return new Promise((resolve, reject) => {
    try {
      // Store all of data chunks returned from the response data stream
      // into an array then use Array#join() to use the returned contents as a String
      let responseDataChunks: Array<Uint8Array> = [];

      // Attach a 'data' listener to add the chunks of data to our array
      // Each chunk is a Buffer instance
      response.Body?.on("data", (chunk: Buffer) => responseDataChunks.push(chunk));

      // Once the stream has no more data, join the chunks into a string and return the string
      response.Body?.once("end", () => resolve(Buffer.concat(responseDataChunks)));
    } catch (error) {
      // Handle the error or throw
      console.error(
        JSON.stringify({
          level: "error",
          severity: 2,
          msg: `Failed to retrieve object from S3: ${bucket}/${key}}`,
          error: (error as Error).message,
        })
      );

      // Log full error to console, it will not be sent to Slack
      console.error(error);

      return reject(error);
    }
  });
}

export async function retrieveFilesFromReliabilityStorage(filePaths: string[]) {
  try {
    const files = filePaths.map(async (filePath) => {
      const result = await getObject(reliabilityBucketName, filePath);
      return (result as Buffer).toString("base64");
    });
    return await Promise.all(files);
  } catch (error) {
    console.error(error);
    throw new Error(`Failed to retrieve files from reliability storage: ${filePaths.toString()}`);
  }
}

export async function copyFilesFromReliabilityToVaultStorage(filePaths: string[]) {
  try {
    for (const filePath of filePaths) {
      const commandInput = {
        Bucket: vaultBucketName,
        CopySource: encodeURI(`${reliabilityBucketName}/${filePath}`),
        Key: filePath,
      };

      await s3Client.send(new CopyObjectCommand(commandInput));
    }
  } catch (error) {
    console.error(error);
    throw new Error(
      `Failed to copy files from reliability storage to vault storage: ${filePaths.toString()}`
    );
  }
}

export async function removeFilesFromReliabilityStorage(filePaths: string[]) {
  try {
    for (const filePath of filePaths) {
      const commandInput = {
        Bucket: reliabilityBucketName,
        Key: filePath,
      };

      await s3Client.send(new DeleteObjectCommand(commandInput));
    }
  } catch (error) {
    console.log(error);
    throw new Error(`Failed to remove files from reliability storage: ${filePaths.toString()}`);
  }
}

export const getFileTags = async (filePath: string) => {
  try {
    const response = await s3Client.send(
      new GetObjectTaggingCommand({
        Bucket: reliabilityBucketName,
        Key: filePath,
      })
    );
    const tags = response.TagSet;

    if (!tags) {
      throw new Error(`No tags found for file: ${filePath}`);
    }

    return tags;
  } catch (error) {
    console.error(error);
    throw new Error(`Failed to retrieve tags for file: ${filePath}`);
  }
};

export const getFileMetaData = async (filePath: string) => {
  const response = await s3Client
    .send(
      new HeadObjectCommand({
        Bucket: reliabilityBucketName,
        Key: filePath,
      })
    )
    .catch((error) => {
      console.error(error);
      throw new Error(`Failed to retrieve metadata for file: ${filePath}`);
    });

  const metadata = response.Metadata;

  if (!metadata) {
    throw new Error(`No metadata found for file: ${filePath}`);
  }

  return metadata;
};
export async function getObjectFirst100BytesInReliabilityBucket(
  objectKey: string
): Promise<Uint8Array<ArrayBufferLike>> {
  const response = await s3Client.send(
    new GetObjectCommand({
      Bucket: reliabilityBucketName,
      Key: objectKey,
      Range: "bytes=0-99",
    })
  );

  const bytes = await response.Body?.transformToByteArray();

  if (bytes === undefined) {
    throw new Error("Object first 100 bytes failed to be retrieved");
  }

  return bytes;
}
