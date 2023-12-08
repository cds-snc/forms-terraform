import {
  S3Client,
  GetObjectCommand,
  CopyObjectCommand,
  DeleteObjectCommand,
} from "@aws-sdk/client-s3";
import { NodeJsClient } from "@smithy/types";

const awsProperties = {
  region: process.env.REGION ?? "ca-central-1",
  ...(process.env.LOCALSTACK === "true" && {
    endpoint: "http://host.docker.internal:4566",
  }),
};

const s3Client = new S3Client({
  ...awsProperties,
  forcePathStyle: true,
}) as NodeJsClient<S3Client>;

const environment =
  process.env.ENVIRONMENT || (process.env.LOCALSTACK === "true" ? "local" : "staging");
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
      console.error(JSON.stringify(error));

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
    console.error(JSON.stringify(error));
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
    console.error(JSON.stringify(error));
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
    console.log(JSON.stringify(error));
    throw new Error(`Failed to remove files from reliability storage: ${filePaths.toString()}`);
  }
}
