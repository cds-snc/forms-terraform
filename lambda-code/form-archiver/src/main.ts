import { Handler } from "aws-lambda";
import { PostgresConnector } from "@gcforms/connectors";

const postgresConnector = await PostgresConnector.defaultUsingPostgresConnectionUrlFromAwsSecret(
  process.env.DB_URL ?? ""
);

export const handler: Handler = async () => {
  try {
    // Delete all form templates that have been marked as archived (has an TTL value that is not null)
    await postgresConnector.executeSqlStatement()`DELETE FROM "Template" WHERE ttl IS NOT NULL AND ttl < CURRENT_TIMESTAMP`;

    console.log(
      JSON.stringify({
        level: "info",
        status: "success",
        msg: "Form Archiver ran successfully.",
      })
    );
  } catch (error) {
    // Error Message will be sent to slack
    console.error(
      JSON.stringify({
        level: "error",
        status: "failed",
        msg: "Failed to run Form Templates Archiver.",
        error: (error as Error).message,
      })
    );

    throw error;
  }
};
