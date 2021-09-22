const {
  S3Client,
  GetObjectCommand,
  CopyObjectCommand,
  DeleteObjectCommand,
} = require("@aws-sdk/client-s3");

const s3Client = new S3Client({ region: process.env.REGION });

const reliabilityBucketName = "forms-staging-reliability-file-storage";
const vaultBucketName = "forms-staging-vault-file-storage";

function getObject(bucket, key) {
  return new Promise(async (resolve, reject) => {
    const getObjectCommand = new GetObjectCommand({
      Bucket: bucket,
      Key: key,
    });

    try {
      const response = await s3Client.send(getObjectCommand);

      // Store all of data chunks returned from the response data stream
      // into an array then use Array#join() to use the returned contents as a String
      let responseDataChunks = [];

      // Attach a 'data' listener to add the chunks of data to our array
      // Each chunk is a Buffer instance
      response.Body.on("data", (chunk) => responseDataChunks.push(chunk));

      // Once the stream has no more data, join the chunks into a string and return the string
      response.Body.once("end", () => resolve(Buffer.concat(responseDataChunks)));
    } catch (err) {
      // Handle the error or throw
      return reject(err);
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
  } catch (err) {
    console.error(err);
    throw new Error("Could not retrieve files");
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

      console.log(commandInput);

      const response = await s3Client.send(new CopyObjectCommand(commandInput)).catch((err) => {
        console.error(err);
        throw new Error("Argh.. there's a problem here");
      });
      console.log(response);
    }
  } catch (err) {
    console.error(err);
    throw new Error("Could not copy files");
  }
}

async function removeFilesFromReliabilityStorage(filePaths) {
  for (const filePath of filePaths) {
    const commandInput = {
      Bucket: reliabilityBucketName,
      Key: filePath,
    };

    await s3Client.send(new DeleteObjectCommand(commandInput));
  }
}

module.exports = {
  retrieveFilesFromReliabilityStorage,
  copyFilesFromReliabilityToVaultStorage,
  removeFilesFromReliabilityStorage,
};
