const { RDSDataClient, ExecuteStatementCommand } = require("@aws-sdk/client-rds-data");
const REGION = process.env.REGION;

exports.handler = async function (event) {
  const dbClient = new RDSDataClient({ region: REGION });
  const method = event.method;

  let SQL, parameters;

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

  let formID = event.formID ? event.formID : null,
    json_config = event.json_config ? "'" + JSON.stringify(event.json_config) + "'" : null;

  switch (method) {
    case "INSERT":
      if (json_config) {
        SQL = "INSERT INTO Templates (json_config) VALUES (:json_config)";
        parameters = [
          {
            name: "json_config",
            typeHint: "JSON",
            value: {
              stringValue: JSON.stringify(event.json_config),
            },
          },
        ];
      } else {
        return { error: "Missing required JSON" };
      }
      break;
    case "GET":
      // Get a specific form if given the id, all forms if not
      if (formID) {
        SQL = "SELECT * FROM Templates WHERE id = :formID";
        parameters = [
          {
            name: "formID",
            value: {
              longValue: formID,
            },
          },
        ];
      } else {
        SQL = "SELECT * FROM Templates";
      }
      break;
    case "UPDATE":
      // needs the ID and the new json blob
      if (formID && json_config) {
        SQL = "UPDATE Templates SET json_config = :json_config WHERE id = :formID";
        parameters = [
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
              stringValue: JSON.stringify(event.json_config),
            },
          },
        ];
      } else {
        return { error: "Missing required Parameter" };
      }
      break;
    case "DELETE":
      // needs the ID
      if (formID) {
        SQL = "DELETE from Templates WHERE id = :formID";
        parameters = [
          {
            name: "formID",
            value: {
              longValue: formID,
            },
          },
        ];
      } else {
        return { error: "Missing required Parameter: FormID" };
      }
      break;
  }

  if (!SQL) {
    return { error: "Method not supported" };
  }

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
      console.log("success");

      if (data.records && data.records.length > 0) {
        return { data: parseConfig(data.records) };
      }
      return { data: data };
    })
    .catch((error) => {
      console.log("error:");
      console.log(error);
      return { error: error };
    });
};

const parseConfig = (records) => {
  const parsedRecords = records.map((record) => {
    return {
      formID: record[0].longValue,
      json_config: JSON.parse(record[1].stringValue.trim(1, -1)) || undefined,
      isNull: record[2].isNull || undefined,
    };
  });
  return { records: parsedRecords };
};
