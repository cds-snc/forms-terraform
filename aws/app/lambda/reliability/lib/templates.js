const { RDSDataClient, ExecuteStatementCommand } = require("@aws-sdk/client-rds-data");
const { Client } = require("pg");
const util = require("util");

const REGION = process.env.REGION;

/**
 * Get's the Form property on the Form Configuration
 * @param {string} formID
 * @returns Form property of Form Configuration
 */
const getTemplateFormConfig = async (formID) => {
  try {
    // Return early if require params not provided
    if (formID === null || typeof formID === "undefined") {
      console.error(`Can not retrieve template form config because no form ID was provided`);
      return null;
    }

    const { SQL, parameters } = createSQLString(formID);

    const getTemplateData = process.env.AWS_SAM_LOCAL ? requestSAM : requestRDS;

    const data = await getTemplateData(SQL, parameters);

    if (data.records.length === 1) {
      return { ...data.records[0].formConfig };
    } else {
      return null;
    }
  } catch (error) {
    // Return as if no template with ID was found.
    // Handle error in calling function if template is not found.
    console.error(`Failed to retrieve template form config because of following error: ${error.message}`);
    return null;
  }
};

/**
 * Delete all form templates that have been marked as archived (has an TTL value that is not null)
 */
const deleteFormTemplatesMarkedAsArchived = async () => {
  try {
    const request = `DELETE FROM "Template" WHERE ttl IS NOT NULL AND ttl < CURRENT_TIMESTAMP`;
    const database = process.env.AWS_SAM_LOCAL ? requestSAM : requestRDS;
    await database(request, []);
  } catch (error) {
    console.error(`{"status": "error", "error": "${error.message}"}`);
    throw new Error("Failed to delete archived form templates");
  }
};

/**
 * Creates and processes request to LOCAL AWS SAM DB
 * @param {string} SQL
 * @param {string[]} parameters
 * @returns PG Client return value
 */
const requestSAM = async (SQL, parameters) => {
  // Placed outside of try block to be referenced in finally
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
    console.error(`{"status": "error", "error": "${error.message}"}`);
    // Lift more generic error to be able to capture event info higher in scope
    throw new Error("Error connecting to LOCAL AWS SAM DB");
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
    console.error(`{"status": "error", "error": "${error.message}"}`);
    // Lift more generic error to be able to capture event info higher in scope
    throw new Error("Error connecting to RDS");
  }
};

/**
 * Creates correct SQL string and params depending on environment
 * @param {string} formID
 */
const createSQLString = (formID) => {
  const selectSQL = `SELECT "jsonConfig" FROM "Template"`;
  if (!process.env.AWS_SAM_LOCAL) {
    return {
      SQL: `${selectSQL} WHERE id = :formID`,
      parameters: [
        {
          name: "formID",
          value: {
            stringValue: formID,
          },
        },
      ],
    };
  } else {
    return {
      SQL: `${selectSQL} WHERE id = $1`,
      parameters: [formID],
    };
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
  getTemplateFormConfig,
  deleteFormTemplatesMarkedAsArchived,
};
