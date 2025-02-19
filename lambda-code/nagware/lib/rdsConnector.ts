import postgres from "postgres";
import { SecretsManagerClient, GetSecretValueCommand } from "@aws-sdk/client-secrets-manager";

const getConnectionString = async (): Promise<string> => {
  try {
    const client = new SecretsManagerClient();
    const command = new GetSecretValueCommand({ SecretId: process.env.DB_URL });

    return client.send(command).then(({ SecretString: secretUrl }) => {
      if (secretUrl === undefined) {
        throw new Error("RDS Conneciton URL is undefined");
      }
      return secretUrl;
    });
  } catch (error) {
    console.error(error, "[database-connector] Failed to retrieve server-database-url");

    throw error;
  }
};

const createDatabaseConnector = async () => {
  console.info("[database-connector] Creating new database connector");

  const connectionString = await getConnectionString();
  return postgres(connectionString);
};

export const DatabaseConnectorClient = await createDatabaseConnector();
