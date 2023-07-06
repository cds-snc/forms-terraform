const { RDSDataClient, ExecuteStatementCommand } = require("@aws-sdk/client-rds-data");
const { Client } = require("pg");

const REGION = process.env.REGION;

/**
 * Delete all form templates that have been marked as archived (has an TTL value that is not null)
 */
const deleteFormTemplatesMarkedAsArchived = async () => {
  try {
    const request = `DELETE FROM "Template" WHERE ttl IS NOT NULL AND ttl < CURRENT_TIMESTAMP`;
    const database = process.env.AWS_SAM_LOCAL ? requestSAM : requestRDS;
    await database(request, []);
  } catch (error) {
    // Warn Message will be sent to slack
    console.warn(
      JSON.stringify({
        level: "warn",
        msg: `Failed to delete form templates marked as archived.`,
        error: error.message,
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
const requestSAM = async (SQL, parameters) => {
  const dbClient = new Client();

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
    throw new Error(`Failed to execute SQL request within LOCAL AWS SAM DB. Reason: ${error.message}.`);
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
const requestRDS = async (SQL, parameters) => {
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
    throw new Error(`Failed to execute SQL request within RDS. Reason: ${error.message}.`);
  }
};

const parseConfig = (records) => {
  if (records) {
    const parsedRecords = records.map((record) => {
      let formConfig;
      if (!process.env.AWS_SAM_LOCAL) {
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

module.exports = {
  deleteFormTemplatesMarkedAsArchived,
};
