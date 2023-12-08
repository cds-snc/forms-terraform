import { RDSDataClient, ExecuteStatementCommand } from "@aws-sdk/client-rds-data";
import pg from "pg";

const REGION = process.env.REGION;

/**
 * Delete all form templates that have been marked as archived (has an TTL value that is not null)
 */
const deleteFormTemplatesMarkedAsArchived = async () => {
  try {
    const request = `DELETE FROM "Template" WHERE ttl IS NOT NULL AND ttl < CURRENT_TIMESTAMP`;
    const database = process.env.LOCALSTACK === "true" ? requestSAM : requestRDS;
    await database(request, []);
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

/**
 * Creates and processes request to LOCAL AWS SAM DB
 * @param {string} SQL
 * @param {string[]} parameters
 * @returns PG Client return value
 */
const requestSAM = async (SQL: string, parameters: Array<string>) => {
  const dbClient = new pg.Client();

  try {
    if (
      process.env.PGHOST &&
      process.env.PGUSER &&
      process.env.PGDATABASE &&
      process.env.PGPASSWORD
    ) {
      dbClient.connect();
    } else {
      throw new Error("Missing Environment Variables for DB config");
    }

    const data = await dbClient.query(SQL, parameters);

    return parseConfig(data.rows);
  } catch (error) {
    throw new Error(
      `Error issuing command to Local SAM AWS DB. Reason: ${(error as Error).message}.`
    );
  } finally {
    dbClient.end();
  }
};

/**
 * Creates and processes request to RDS
 * @param {string} SQL
 * @param {{name: string, value: {stringValue: string}[]}} parameters
 * @returns RDS client return value
 */
const requestRDS = async (
  SQL: string,
  parameters: { name: string; value: { stringValue: string } }[]
) => {
  try {
    const dbClient = new RDSDataClient({ region: REGION });

    const params = {
      database: process.env.DB_NAME,
      resourceArn: process.env.DB_ARN,
      secretArn: process.env.DB_SECRET,
      sql: SQL,
      includeResultMetadata: false, // set to true if we want metadata like column names
      parameters: parameters,
    };

    const command = new ExecuteStatementCommand(params);

    const data = await dbClient.send(command);

    return parseConfig(data.records);
  } catch (error) {
    throw new Error(`Error issuing command to AWS RDS. Reason: ${(error as Error).message}.`);
  }
};

const parseConfig = (records: any[] | undefined) => {
  if (records) {
    const parsedRecords = records.map((record) => {
      let formConfig;
      if (!(process.env.LOCALSTACK === "true")) {
        formConfig = JSON.parse(record[0].stringValue.trim(1, -1)) || undefined;
      } else {
        formConfig = record.jsonConfig;
      }
      return {
        formConfig,
      };
    });

    return { records: parsedRecords };
  }

  return { records: [] };
};

export { deleteFormTemplatesMarkedAsArchived };
