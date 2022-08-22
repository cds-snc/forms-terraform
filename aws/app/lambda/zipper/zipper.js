"use strict";

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
    ["nod.gif", "upload.txt", "upload1.txt"].map(async (file) => ({
      name: file,
      object: await getS3Ojbect(BUCKET_NAME, file),
    }))
  );

  // Upload zip to S3
  const buffer = await createArchive(s3Objects);
  const upload = new Upload({
    client: s3Client,
    params: {
      Bucket: BUCKET_NAME,
      Key: "file.zip",
      Body: buffer,
      ContentType: "application/zip"
    },
  });
  await upload.done();
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

const getS3Ojbect = async (bucket, key) => {
  return await s3Client.send(
    new GetObjectCommand({
      Bucket: bucket,
      Key: key,
    })
  );
};

// Somewhat uselss for us since there's a 6MB limit on lambda request/response body size
const formatResponse = (data) => ({
  statusCode: 200,
  headers: {
    "Content-Type": "application/zip",
    "Content-disposition": "attachment; filename=files.zip",
  },
  isBase64Encoded: true,
  body: data.toString("base64"),
});
