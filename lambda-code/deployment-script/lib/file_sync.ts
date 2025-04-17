import {
  S3Client,
  S3ServiceException,
  // This command supersedes the ListObjectsCommand and is the recommended way to list objects.
  paginateListObjectsV2,
  GetObjectCommand,
  NoSuchKey,
} from "@aws-sdk/client-s3";

import path from "node:path";
import fs from "node:fs";
import { pipeline } from "node:stream/promises";

export const syncS3 = async (bucketName: string, destination: string, pageSize = 5) => {
  const client = new S3Client({});
  const paths = await getS3ObjectPaths(client, bucketName, pageSize);
  const directories = getDirectories(paths);

  createDirectories(directories, destination);
  const downloadPromises = paths.map((key) => {
    return downloadFile(client, bucketName, key, destination);
  });
  await Promise.all(downloadPromises).catch((err) => {
    console.error(err);
    throw new Error(`Error downloading files from S3: ${err}`);
  });
  console.info(`All files downloaded successfully to "${destination}"`);
};

const getS3ObjectPaths = async (client: S3Client, bucketName: string, pageSize: number) => {
  const objects = [];
  try {
    const paginator = paginateListObjectsV2(
      { client, /* Max items per page */ pageSize },
      { Bucket: bucketName }
    );

    for await (const page of paginator) {
      if (!page.Contents) {
        break;
      }

      objects.push(...page.Contents.map((o) => o.Key));
    }
    const keys = objects.filter((o) => o !== undefined).flat();

    console.info(`Found ${keys.length} objects in bucket "${bucketName}"`);
    console.info(`Path Keys:\n${keys.map((o) => `• ${o}`).join("\n")}\n`);

    return keys;
  } catch (caught) {
    if (caught instanceof S3ServiceException && caught.name === "NoSuchBucket") {
      throw new Error(
        `Error from S3 while listing objects for "${bucketName}". The bucket doesn't exist.`
      );
    } else if (caught instanceof S3ServiceException) {
      throw new Error(
        `Error from S3 while listing objects for "${bucketName}".  ${caught.name}: ${caught.message}`
      );
    } else {
      throw caught;
    }
  }
};

const getDirectories = (paths: string[]) => {
  const directories = paths.map((path) => path.split("/").slice(0, -1).join("/"));
  const uniqueDirectories = [...new Set(directories)].sort(
    (a, b) => a.split("/").length - b.split("/").length
  );
  return uniqueDirectories;
};

const createDirectories = (directories: string[], destination: string) => {
  directories.forEach((directory) => {
    const dirPath = path.join(destination, directory);
    if (!fs.existsSync(dirPath)) {
      fs.mkdirSync(dirPath, { recursive: true });
    }
  });
};

const downloadFile = async (
  s3Client: S3Client,
  bucket: string,
  key: string,
  destination: string
) => {
  try {
    const response = await s3Client.send(
      new GetObjectCommand({
        Bucket: bucket,
        Key: key,
      })
    );

    const fileStream = response.Body?.transformToWebStream();
    if (!fileStream) {
      throw new Error(`Error downloading file: ${key}`);
    }
    const filePath = path.join(destination, key);
    return pipeline(fileStream, fs.createWriteStream(filePath, { flags: "w+" })).catch((err) => {
      console.error(err);
      throw new Error(`Error writing file to disk: ${filePath}`);
    });
  } catch (caught) {
    if (caught instanceof NoSuchKey) {
      throw new Error(
        `Error from S3 while getting object "${key}" from "${bucket}". No such key exists.`
      );
    } else if (caught instanceof S3ServiceException) {
      throw new Error(
        `Error from S3 while getting object from ${bucket}.  ${caught.name}: ${caught.message}`
      );
    } else {
      throw caught;
    }
  }
};
