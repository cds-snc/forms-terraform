const { RDSDataClient, ExecuteStatementCommand } = require("@aws-sdk/client-rds-data");
const { Client } = require("pg");

const REGION = process.env.REGION;

const formatError = (err) => {
  return typeof err === "object" ? JSON.stringify(err) : err;
};

//TODO better error handling? return a non 200?

exports.handler = async function (event) {
  var dbClient;
  // Connect to either local or AWS db
  if (process.env.AWS_SAM_LOCAL) {
    dbClient = new Client();
    if (
      process.env.PGHOST &&
      process.env.PGUSER &&
      process.env.PGDATABASE &&
      process.env.PGPASSWORD
    ) {
      dbClient.connect();
    } else {
      return "Missing Environment Variables for DB config";
    }
  } else {
    dbClient = new RDSDataClient({ region: REGION });
  }

  /*
    Supported Methods:
    INSERT:
      - (Required) json_config - json config string defining a form
    GET:
      - (Optional) formID. Returns all entries if not provided
    UPDATE:
      - (Required) formID to update
      - (Required) json_config - new json config string to update the entry
    DELETE:
      - (Required) formID to delete
  */
  const method = event.method;
  let formID = event.formID ? parseInt(event.formID) : null,
    formConfig = event.formConfig ? "'" + JSON.stringify(event.formConfig) + "'" : null;

  // if formID is NaN, assign it to an id we know will return no records
  if (isNaN(formID)) formID = 1;

  let SQL = "",
    parameters = [];

  switch (method) {
    case "INSERT":
      if (formConfig) {
        SQL = !process.env.AWS_SAM_LOCAL
          ? "INSERT INTO Templates (json_config) VALUES (:json_config) RETURNING id"
          : "INSERT INTO Templates (json_config) VALUES ($1) RETURNING id";
        parameters = !process.env.AWS_SAM_LOCAL
          ? [
              {
                name: "json_config",
                typeHint: "JSON",
                value: {
                  stringValue: JSON.stringify(event.formConfig),
                },
              },
            ]
          : [JSON.stringify(event.formConfig)];
      } else {
        return { error: "Missing required JSON" };
      }
      break;
    case "GET":
      // Get a specific form if given the id, all forms if not
      if (formID) {
        SQL = !process.env.AWS_SAM_LOCAL
          ? "SELECT * FROM Templates WHERE id = :formID"
          : "SELECT * FROM Templates WHERE id = ($1)";
        parameters = !process.env.AWS_SAM_LOCAL
          ? [
              {
                name: "formID",
                value: {
                  longValue: formID,
                },
              },
            ]
          : [formID];
      } else {
        SQL = "SELECT * FROM Templates";
      }
      break;
    case "UPDATE":
      // needs the ID and the new json blob
      if (formID && formConfig) {
        SQL = !process.env.AWS_SAM_LOCAL
          ? "UPDATE Templates SET json_config = :json_config WHERE id = :formID"
          : "UPDATE Templates SET json_config = ($1) WHERE id = ($2)";
        parameters = !process.env.AWS_SAM_LOCAL
          ? [
              {
                name: "formID",
                value: {
                  longValue: formID,
                },
              },
              {
                name: "json_config",
                typeHint: "JSON",
                value: {
                  stringValue: JSON.stringify(event.formConfig),
                },
              },
            ]
          : [formID, JSON.stringify(event.formConfig)];
      } else {
        return { error: "Missing required Parameter" };
      }
      break;
    case "DELETE":
      // needs the ID
      if (formID) {
        SQL = !process.env.AWS_SAM_LOCAL
          ? "DELETE from Templates WHERE id = :formID"
          : "DELETE from Templates WHERE id = ($1)";
        parameters = !process.env.AWS_SAM_LOCAL
          ? [
              {
                name: "formID",
                value: {
                  longValue: formID,
                },
              },
            ]
          : [formID];
      } else {
        return { error: "Missing required Parameter: FormID" };
      }
      break;
  }

  if (!SQL) {
    return { error: "Method not supported" };
  }

  if (process.env.AWS_SAM_LOCAL) {
    return await dbClient
      .query(SQL, parameters)
      .then((data) => {
        if (data.rows && data.rows.length > 0) {
          return { data: parseConfig(data.rows) };
        }
        return { data: data };
      })
      .catch((error) => {
        console.error(
          `{"status": "error", "error": "${formatError(error)}", "event": "${formatError(event)}"}`
        );
        return { error: error };
      });
  } else {
    const params = {
      database: process.env.DB_NAME,
      resourceArn: process.env.DB_ARN,
      secretArn: process.env.DB_SECRET,
      sql: SQL,
      includeResultMetadata: false, // set to true if we want metadata like column names
      parameters: parameters,
    };
    const command = new ExecuteStatementCommand(params);
    return await dbClient
      .send(command)
      .then((data) => {
        if (data.records && data.records.length > 0) {
          return { data: parseConfig(data.records) };
        }
        return { data: data };
      })
      .catch((error) => {
        console.error(
          `{"status": "error", "error": "${formatError(error)}", "event": "${formatError(event)}"}`
        );
        return { error: error };
      });
  }
};

const parseConfig = (records) => {
  const parsedRecords = records.map((record) => {
    let formID, formConfig, organization;
    if (!process.env.AWS_SAM_LOCAL) {
      formID = record[0].longValue;
      if (record.length > 1) {
        formConfig = JSON.parse(record[1].stringValue.trim(1, -1)) || undefined;
        organization = record[2].isNull || undefined;
      }
    } else {
      formID = record.id;
      formConfig = record.json_config;
      organization = record.organisation;
    }

    return {
      formID: formID,
      formConfig: formConfig,
      organization: organization,
    };
  });
  return { records: parsedRecords };
};
