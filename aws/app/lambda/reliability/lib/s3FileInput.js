const {
  S3Client,
  GetObjectCommand,
  CopyObjectCommand,
  DeleteObjectCommand,
} = require("@aws-sdk/client-s3");

const s3Client = new S3Client({
  region: process.env.REGION,
  ...(process.env.AWS_SAM_LOCAL && {
    endpoint: "http://host.docker.internal:4566",
    forcePathStyle: true,
  }),
});

const environment = process.env.ENVIRONMENT || (process.env.AWS_SAM_LOCAL ? "local" : "staging");
const reliabilityBucketName = `forms-${environment}-reliability-file-storage`;
const vaultBucketName = `forms-${environment}-vault-file-storage`;

async function getObject(bucket, key) {
  const getObjectCommand = new GetObjectCommand({
    Bucket: bucket,
    Key: key,
  });
  const response = await s3Client.send(getObjectCommand);

  return new Promise((resolve, reject) => {
    try {
      // Store all of data chunks returned from the response data stream
      // into an array then use Array#join() to use the returned contents as a String
      let responseDataChunks = [];

      // Attach a 'data' listener to add the chunks of data to our array
      // Each chunk is a Buffer instance
      response.Body.on("data", (chunk) => responseDataChunks.push(chunk));

      // Once the stream has no more data, join the chunks into a string and return the string
      response.Body.once("end", () => resolve(Buffer.concat(responseDataChunks)));
    } catch (error) {
      // Handle the error or throw
      console.error(
        JSON.stringify({
          level: "error",
          msg: `Failed to retrieve object from S3: ${bucket}/${key}}`,
          error: error.message,
        })
      );

      // Log full error to console, it will not be sent to Slack
      console.error(JSON.stringify(error));

      return reject(error);
    }
  });
}

async function retrieveFilesFromReliabilityStorage(filePaths) {
  try {
    const files = filePaths.map(async (filePath) => {
      const result = await getObject(reliabilityBucketName, filePath);
      return result.toString("base64");
    });
    return await Promise.all(files);
  } catch (error) {
    console.error(JSON.stringify(error));
    throw new Error(`Failed to retrieve files from reliability storage: ${filePaths.toString()}`);
  }
}

async function copyFilesFromReliabilityToVaultStorage(filePaths) {
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

async function removeFilesFromReliabilityStorage(filePaths) {
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

module.exports = {
  retrieveFilesFromReliabilityStorage,
  copyFilesFromReliabilityToVaultStorage,
  removeFilesFromReliabilityStorage,
};
