import { RDSDataClient, ExecuteStatementCommand } from "@aws-sdk/client-rds-data";

/**
 * Delete all form templates that have been marked as archived (has an TTL value that is not null)
 */
export const deleteFormTemplatesMarkedAsArchived = async () => {
  try {
    const rdsDataClient = new RDSDataClient({ region: process.env.REGION });

    const executeStatementCommand = new ExecuteStatementCommand({
      database: process.env.DB_NAME,
      resourceArn: process.env.DB_ARN,
      secretArn: process.env.DB_SECRET,
      sql: `DELETE FROM "Template" WHERE ttl IS NOT NULL AND ttl < CURRENT_TIMESTAMP`,
      includeResultMetadata: false, // set to true if we want metadata like column names
    });

    await rdsDataClient.send(executeStatementCommand);
  } catch (error) {
    // Warn Message will be sent to slack
    console.warn(
      JSON.stringify({
        level: "warn",
        msg: `Failed to delete form templates marked as archived.`,
        error: (error as Error).message,
      })
    );
  }
};
