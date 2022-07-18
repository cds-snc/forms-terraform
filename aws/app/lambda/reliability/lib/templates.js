const { RDSDataClient, ExecuteStatementCommand } = require("@aws-sdk/client-rds-data");
const { Client } = require("pg");

const REGION = process.env.REGION;

const formatError = (err) => {
  return typeof err === "object" ? JSON.stringify(err) : err;
};

const getTemplateFormConfig = (formID) => {

  try {

    // Return early if require params not provided
    if (formID === null || typeof formID === "undefined") return { error: "Missing formID" };

    const { SQL, parameters } = createSQLString(formID);

    const getTemplateData = process.env.AWS_SAM_LOCAL ? requestSAM : requestRDS;

    const data = await getTemplateData(SQL, parameters);

    if (Array.isArray(data?.rows) && data.rows.length === 1) {
      
      return {...data.rows[0].json_config}
    } else {
      return null;
    }
  } catch (e) {
    console.error(
      `{"status": "error", "error": "${formatError(error)}"}`
    );
    // Return as if no template with ID was found.
    // Handle error in calling function if template is not found.
    return { data: [] };
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
    return await dbClient.query(SQL, parameters);
  } catch (error) {
    console.error(`{"status": "error", "error": "${formatError(error)}"}`);
    // Lift more generic error to be able to capture event info higher in scope
    throw new Error("Error connecting to LOCAL AWS SAM DB");
  } finally {
    dbClient.end();
  }
};

/**
 * Creates and processes request to RDS
 * @param {string} SQL
 * @param {{name: string, value: {longValue: string}[]}} parameters
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

    return await dbClient.send(command);
  } catch (error) {
    console.error(`{"status": "error", "error": "${formatError(error)}"}`);
    // Lift more generic error to be able to capture event info higher in scope
    throw new Error("Error connecting to RDS");
  }
};

/**
 * Creates correct SQL string and params depending on environment
 * @param {string} formID
 */
const createSQLString = (formID) => {
  const selectSQL = "SELECT json_config FROM Templates";
  if (!process.env.AWS_SAM_LOCAL) {
    return {
      SQL: `${selectSQL} WHERE id = :formID`,
      parameters: [
        {
          name: "formID",
          value: {
            longValue: formID,
          },
        },
      ],
    };
  } else {
    return {
      SQL: `${selectSQL} WHERE id = ($1)`,
      parameters: [formID],
    };
  }
};

module.exports = {
  getTemplateFormConfig
}