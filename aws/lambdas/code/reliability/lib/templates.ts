import { RDSDataClient, ExecuteStatementCommand } from "@aws-sdk/client-rds-data";
import pg from "pg";

const REGION = process.env.REGION;

/**
 * Get's the Form property on the Form Configuration
 * @param {string} formID
 * @returns Form property of Form Configuration including Delivery option
 */
export const getTemplateFormConfig = async (formID: string) => {
  try {
    // Return early if require params not provided
    if (formID === null || typeof formID === "undefined") {
      console.warn(
        JSON.stringify({
          msg: "Can not retrieve template form config because no form ID was provided",
        })
      );
      return null;
    }

    const { SQL, parameters } = createSQLString(formID);

    const getTemplateData = process.env.LOCALSTACK === "true" ? requestSAM : requestRDS;

    // I know it's cheating to use 'any' but we'll refactor later
    const data = await getTemplateData(SQL, parameters as any);

    if (data.records.length === 1) {
      return { ...data.records[0] };
    } else {
      return null;
    }
  } catch (error) {
    console.warn(
      JSON.stringify({
        level: "warn",
        msg: "Failed to retrieve template form config from DB",
        error: (error as Error).message,
      })
    );
    // Log full error to console, it will not be sent to Slack
    console.warn(
      JSON.stringify({
        msg: `Failed to retrieve template form config because of following error: ${
          (error as Error).message
        }`,
      })
    );
    // Return as if no template with ID was found.
    // Handle error in calling function if template is not found.
    return null;
  }
};

/**
 * Creates and processes request to LOCAL AWS SAM DB
 * @param {string} SQL
 * @param {string[]} parameters
 * @returns PG Client return value
 */
const requestSAM = async (SQL: string, parameters: string[]) => {
  // Placed outside of try block to be referenced in finally
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
    console.error(
      JSON.stringify({
        level: "error",
        status: "error",
        msg: "Error issuing command to Local SAM AWS DB",
        error: (error as Error).message,
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
    console.error(
      JSON.stringify({
        level: "error",
        severity: 2,
        status: "error",
        msg: "Error issuing command to AWS RDS",
        error: (error as Error).message,
      })
    );
    // Lift more generic error to be able to capture event info higher in scope
    throw new Error("Error connecting to RDS");
  }
};

/**
 * Creates correct SQL string and params depending on environment
 * @param {string} formID
 */
const createSQLString = (formID: string) => {
  const selectSQL = `SELECT  t."jsonConfig", deli."emailAddress", deli."emailSubjectEn", deli."emailSubjectFr"
                    FROM "Template" t
                    LEFT JOIN "DeliveryOption" deli ON t.id = deli."templateId"`;
  if (!(process.env.LOCALSTACK === "true")) {
    return {
      SQL: `${selectSQL} WHERE t.id = :formID`,
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
      SQL: `${selectSQL} WHERE t.id = $1`,
      parameters: [formID],
    };
  }
};

const parseConfig = (records: any[] | undefined) => {
  if (records) {
    const parsedRecords = records.map((record) => {
      let formConfig;
      let deliveryOption;
      if (!(process.env.LOCALSTACK === "true")) {
        formConfig = JSON.parse(record[0].stringValue.trim(1, -1)) || undefined;
        deliveryOption = record[1].stringValue
          ? {
              emailAddress: record[1].stringValue,
              emailSubjectEn: record[2].stringValue,
              emailSubjectFr: record[3].stringValue,
            }
          : null;
      } else {
        formConfig = record.jsonConfig;
        deliveryOption = record.emailAddress
          ? {
              emailAddress: record.emailAddress,
              emailSubjectEn: record.emailSubjectEn,
              emailSubjectFr: record.emailSubjectFr,
            }
          : null;
      }

      return {
        formConfig,
        deliveryOption,
      };
    });
    return { records: parsedRecords };
  }

  return { records: [] };
};
