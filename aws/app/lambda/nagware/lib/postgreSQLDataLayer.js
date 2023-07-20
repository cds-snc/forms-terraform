const { RDSDataClient, ExecuteStatementCommand } = require("@aws-sdk/client-rds-data");
const { Client } = require("pg");

async function getFormNameAndUserEmailAddresses(formID) {
  try {
    const { SQL, parameters } = createSQLString(formID);
    const requestFornNameAndOwnerEmailAddress = process.env.AWS_SAM_LOCAL ? requestSAM : requestRDS;
    const formNameAndUserEmailAddresses = await requestFornNameAndOwnerEmailAddress(SQL, parameters);

    if (formNameAndUserEmailAddresses) {
      return formNameAndUserEmailAddresses;
    } else {
      throw new Error(`Could not find any owner email address associated to Form ID: ${formID}.`);
    }
  } catch (error) {
    throw new Error(`Failed to retrieve owner email address. Reason: ${error.message}.`);
  }
}

const createSQLString = (formID) => {
  const selectSQL = `SELECT usr."email", tem."name", tem."jsonConfig" FROM "User" usr JOIN "_TemplateToUser" ttu ON usr."id" = ttu."B" JOIN "Template" tem ON tem."id" = ttu."A"`;
  if (!process.env.AWS_SAM_LOCAL) {
    return {
      SQL: `${selectSQL} WHERE ttu."A" = :formID`,
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
      SQL: `${selectSQL} WHERE ttu."A" = $1`,
      parameters: [formID],
    };
  }
};

const parseQueryResponse = (records) => {
  if (records.length === 0) return null;

  let formName = "";

  const firstRecord = records[0];

  if (!process.env.AWS_SAM_LOCAL) {
    const jsonConfig = JSON.parse(firstRecord[2].stringValue.trim(1, -1)) || undefined;
    formName = firstRecord[1].stringValue !== "" ? firstRecord[1].stringValue : `${jsonConfig.titleEn} - ${jsonConfig.titleFr}`;
  } else {
    formName = firstRecord.name !== "" ? firstRecord.name : `${firstRecord.jsonConfig.titleEn} - ${firstRecord.jsonConfig.titleFr}`;
  }

  const emailAddresses = records.map((record) => {
    if (!process.env.AWS_SAM_LOCAL) {
      return record[0].stringValue;
    } else {
      return record.email;
    }
  });

  return { formName, emailAddresses };
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
    return parseQueryResponse(data.rows);
  } catch (error) {
    console.error(
      JSON.stringify({
        status: "error",
        error: error.message,
      })
    );
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
    const dbClient = new RDSDataClient({ region: process.env.REGION });
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
    return parseQueryResponse(data.records);
  } catch (error) {
    console.error(
      JSON.stringify({
        status: "error",
        error: error.message,
      })
    );
    // Lift more generic error to be able to capture event info higher in scope
    throw new Error("Error connecting to RDS");
  }
};

module.exports = {
  getFormNameAndUserEmailAddresses,
};