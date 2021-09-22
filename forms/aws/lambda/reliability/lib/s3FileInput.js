const { S3Client, GetObjectCommand, CopyObjectCommand, DeleteObjectCommand } = require("@aws-sdk/client-s3");

const s3Client = new S3Client({ region: process.env.REGION });

const reliabilityBucketName = "forms-staging-reliability-file-storage";
const vaultBucketName = "forms-staging-vault-file-storage";

async function retrieveFilesFromReliabilityStorage(filePaths) {
  return filePaths.map(async (filePath) => {
    const commandInput = {
      Bucket: reliabilityBucketName,
      Key: filePath,
    };
  
    const commandOutput = await s3Client.send(new GetObjectCommand(commandInput));
    return commandOutput.Body
  });
}

async function copyFilesFromReliabilityToVaultStorage(filePaths) {
  for (const filePath of filePaths) {
    const commandInput = {
      Bucket: vaultBucketName,
      CopySource: `${reliabilityBucketName}/${filePath}`,
      Key: filePath,
    };
  
    await s3Client.send(new CopyObjectCommand(commandInput));
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

modules.exports = {
  retrieveFilesFromReliabilityStorage,
  copyFilesFromReliabilityToVaultStorage,
  removeFilesFromReliabilityStorage
};
  