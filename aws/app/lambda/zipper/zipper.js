"use strict";

const archiver = require("archiver");
const archiveEncrypted = require("archiver-zip-encrypted");
const pino = require("pino");
const { lambdaRequestTracker, pinoLambdaDestination } = require("pino-lambda");
const { PassThrough } = require("stream");
const { S3Client, GetObjectCommand } = require("@aws-sdk/client-s3");

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
// This should only be done once per
archiver.registerFormat("zip-encrypted", archiveEncrypted);

// Setup logging and add a custom requestId attribute to all log messages
const logger = pino({ level: LOGGING_LEVEL }, pinoLambdaDestination());
const withRequest = lambdaRequestTracker({
  requestMixin: (event, context) => {
    return {
      correlation_id: context.awsRequestId,
    };
  },
});

/**
 * Lambda handler function.
 * @param {Object} event Lambda invocation event
 */
exports.handler = async (event, context) => {
  withRequest(event, context);

  // TODO - extract these from the event and pass object key + filename
  const s3Objects = await Promise.all(
    ["upload.txt", "upload1.txt"].map(async (file) => ({
      name: file,
      object: await getS3Ojbect(BUCKET_NAME, file),
    }))
  );

  return createArchive(s3Objects);
};

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
        resolve(formatResponse(data));
      });

    // Add s3Objects to the zip archive
    for (const s3Object of s3Objects) {
      logger.info(`Adding ${s3Object.name} to archive`);

      const passthrough = new PassThrough();
      s3Object.object.Body.pipe(passthrough);
      archive.append(passthrough, { name: s3Object.name });
    }

    // Everything added, trigger the response
    archive.finalize();
  });
};

const getS3Ojbect = async (bucket, key) => {
  return await s3Client.send(
    new GetObjectCommand({
      Bucket: bucket,
      Key: key,
    })
  );
};

const formatResponse = (data) => ({
  statusCode: 200,
  headers: {
    "Content-Type": "application/zip",
    "Content-disposition": "attachment; filename=files.zip",
  },
  isBase64Encoded: true,
  body: data.toString("base64"),
});
