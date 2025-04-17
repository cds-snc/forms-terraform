import { execFile } from "child_process";
import { SecretsManagerClient, GetSecretValueCommand } from "@aws-sdk/client-secrets-manager";

function getAwsSecret(secretIdentifier: string): Promise<string | undefined> {
  return new SecretsManagerClient()
    .send(new GetSecretValueCommand({ SecretId: secretIdentifier }))
    .then((commandOutput) => commandOutput.SecretString);
}

export const prismaMigrate = async () => {
  if (!process.env.DB_URL_SECRET_ARN) {
    throw new Error("DB_URL_SECRET_ARN is not set");
  }
  console.info("Fetching database URL from AWS Secrets Manager...");
  const DATABASE_URL = await getAwsSecret(process.env.DB_URL_SECRET_ARN);
  process.env.DATABASE_URL = DATABASE_URL + "?connect_timeout=30&pool_timeout=30";
  console.info("Running Prisma migration...");

  await migrate();

  console.info("Migration completed successfully");
};

async function migrate(): Promise<void> {
  console.debug("Migrating database");
  return new Promise((resolve, reject) => {
    execFile(
      "./node_modules/prisma/build/index.js",
      ["migrate", "deploy", "--schema", "/tmp/prisma/schema.prisma"],
      (error, stdout, stderr) => {
        if (error != null) {
          console.error(stderr);
          reject(`prisma migrate exited with error ${error.message}`);
        } else {
          console.log(stdout);
          resolve();
        }
      }
    );
  });
}
