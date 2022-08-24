"use strict";

/**
 * Lambda that accepts a list of S3 object keys, creates an encrypted zip and then
 * uploads the back to the given S3 bucket.
 *
 * S3 event format:
 * {
 *   "submissionId": "123",
 *   "s3ObjectKeys": [
 *     "some/object/key.png",
 *     "another/object/key.png",
 *     "root-key.txt"
 *   ]
 * }
 */

const archiver = require("archiver");
const archiveEncrypted = require("archiver-zip-encrypted");
const pino = require("pino");
const { lambdaRequestTracker, pinoLambdaDestination } = require("pino-lambda");
const { S3Client, GetObjectCommand } = require("@aws-sdk/client-s3");
const { Upload } = require("@aws-sdk/lib-storage");

const REGION = process.env.REGION;
const BUCKET_NAME = process.env.BUCKET_NAME;
const LOGGING_LEVEL = process.env.LOGGING_LEVEL ? process.env.LOGGING_LEVEL : "info";

const s3Client = new S3Client({
  region: REGION,
  ...(process.env.AWS_SAM_LOCAL && {
    endpoint: "http://host.docker.internal:4566",
    forcePathStyle: true,
  }),
});

// Register the password protected zip format.
// This should only be done once on Lambda cold start
archiver.registerFormat("zip-encrypted", archiveEncrypted);

// Setup logging and add a custom submissionId attribute to all log messages
const logger = pino({ level: LOGGING_LEVEL }, pinoLambdaDestination());
const withRequest = lambdaRequestTracker({
  requestMixin: (event) => {
    return {
      correlation_id: event.submissionId,
    };
  },
});

/**
 * Create an archive from the passed in S3 object keys and upload back to the bucket
 * @param {Object} event Lambda invocation event
 */
exports.handler = async (event) => {
  withRequest(event);

  const { submissionId, s3ObjectKeys } = event;

  // Get the S3 objects from from the bucket
  const s3Objects = await Promise.all(
    s3ObjectKeys.map(async (key) => ({
      name: getFileNameFromPath(key),
      object: await getS3Ojbect(BUCKET_NAME, key),
    }))
  );

  // Create the zip archive
  const buffer = await createArchive(s3Objects);

  // Upload the zip archive to the bucket
  const upload = new Upload({
    client: s3Client,
    params: {
      Bucket: BUCKET_NAME,
      Key: `downloads/${submissionId}.zip`,
      Body: buffer,
      ContentType: "application/zip"
    },
  });
  await upload.done();
};

/**
 * Given an array of S3 objects, add them to an ecrypted zip archive and return the archive as a buffer
 * @param {{name: string, object: GetObjectCommandOutput}[]} s3Objects - List of S3 objects to archive
 * @returns {Promise} buffer - Buffer representing the zip archive
 */
const createArchive = (s3Objects) => {
  return new Promise((resolve, reject) => {
    // Compression level, higher = slower/better
    const archive = archiver("zip-encrypted", { zlib: { level: 9 }, encryptionMethod: "aes256", password: "123" });
    const buffer = [];

    archive
      .on("data", (data) => buffer.push(data))
      .on("error", (error) => {
        logger.error(`Failed to archive files: ${error}`);
        reject(error);
      })
      .on("end", () => {
        logger.info(`Created ${archive.pointer()} byte archive`);
        const data = Buffer.concat(buffer);
        resolve(data);
      });

    // Add s3Objects to the zip archive
    for (const s3Object of s3Objects) {
      logger.info(`Adding ${s3Object.name} to archive`);
      archive.append(s3Object.object.Body, { name: s3Object.name });
    }

    // Everything added, trigger the response
    archive.finalize();
  });
};

/**
 * Get an S3 object defined by a given bucket and object key.
 * @param {string} bucket - S3 bucket name
 * @param {string} key - S3 object key
 * @returns {GetObjectCommandOutput} - S3 object response from the GetObjectCommand
 */
const getS3Ojbect = async (bucket, key) => {
  return await s3Client.send(
    new GetObjectCommand({
      Bucket: bucket,
      Key: key,
    })
  );
};

/**
 * Given a file path returns the file name.
 * @param filePath - The file path to get the file name from
 * @returns {string} - The file name
 */
 const getFileNameFromPath = (filePath) => {
  return filePath.substring(filePath.lastIndexOf("/") + 1);
};
