const { RDSDataClient, ExecuteStatementCommand } = require("@aws-sdk/client-rds-data");
const { Client } = require("pg");
const jwt = require("jsonwebtoken");

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
      - (Optional) limit - number of rows to return
      - (Optional) offset - row number where to start
    UPDATE:
      - (Required) formID to update
      - (Required) json_config - new json config string to update the entry
    DELETE:
      - (Required) formID to delete
  */
  const method = event.method;
  let formID = event.formID ? parseInt(event.formID) : null
  let formConfig = event.formConfig ? "'" + JSON.stringify(event.formConfig) + "'" : null;
  let limit = event.limit ? parseInt(event.limit) : null;
  let offset = event.offset ? parseInt(event.offset) : null;

  // if formID is NaN, assign it to an id we know will return no records
  if (isNaN(formID)) formID = 1;

  let SQL = "";
  let parameters = [];
  
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
      SQL = "SELECT id, json_config, organization FROM Templates";
      // Get a specific form if given the id, all forms if not
      if (formID) {
        SQL += !process.env.AWS_SAM_LOCAL
            ? " WHERE id = :formID"
            : " WHERE id = ($1)";

        !process.env.AWS_SAM_LOCAL
            ? parameters.push (
              {
                name: "formID",
                value: {
                  longValue: formID,
                },
              }) 
            : parameters.push(formID);

        // break here since if there is a formID, then "limit" and "offset" aren't needed
        break;
      }
      if (limit) {
        SQL += !process.env.AWS_SAM_LOCAL
          ? " LIMIT :limit"
          : " LIMIT ($1)";

        !process.env.AWS_SAM_LOCAL
          ? parameters.push (
            {
              name: "limit",
              value: {
                longValue: limit,
              },
            }) 
          : parameters.push(limit);
      }
      if (offset) {
        SQL += !process.env.AWS_SAM_LOCAL
          ? " OFFSET :offset"
          : " OFFSET ($2)";

        !process.env.AWS_SAM_LOCAL
          ? parameters.push (
            {
              name: "offset",
              value: {
                longValue: offset,
              },
            }) 
          : parameters.push(offset);          
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
            : [JSON.stringify(event.formConfig), formID];
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
    try{
      const data = await dbClient.query(SQL, parameters);
      if (data.rows && data.rows.length > 0) {
        let returnedData = parseConfig(data.rows);
        // here we need to create the jwt token with the id that was created
        if(method === "INSERT"){
          returnedData = await createBearerToken(dbClient, returnedData.records[0].formID, true)
        }
        return { data: returnedData };
      }
      return { data: data };
    }
    catch(error){
      console.log(error)
      console.error(
          `{"status": "error", "error": "${formatError(error)}", "event": "${formatError(event)}"}`
      );
      return { error: error };
    }
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
    try {
      const data = await dbClient.send(command)
      if (data.records && data.records.length > 0) {
        let returnedData = parseConfig(data.records);
        if ( method === "INSERT"){
          returnedData = await createBearerToken(dbClient, returnedData.records[0].formID, false, params)
        }
        return {data: returnedData};
      }
      return {data: data};
    }
    catch(error){
      console.error(
          `{"status": "error", "error": "${formatError(error)}", "event": "${formatError(event)}"}`
      );
      return { error: error };
    }
  }
};


const parseConfig = (records) => {
  const parsedRecords = records.map((record) => {
    let formID, formConfig, organization;
    if (!process.env.AWS_SAM_LOCAL) {
      formID = record[0].longValue;
      if (record.length > 1) {
        formConfig = JSON.parse(record[1].stringValue.trim(1, -1)) || undefined;
        organization = record[2].stringValue ? record[2].stringValue : null;
      }
    } else {
      formID = record.id;
      formConfig = record.json_config;
      organization = record.organization;
    }

    return {
      formID,
      formConfig,
      organization,
    };
  });
  return { records: parsedRecords };
};

/**
 * function to mint and commit jwt bearer token to the appropriate row in the database
 * @param dbClient - the db client to use to send commands to the db
 * @param formID - the ID of the relevant row this token is being minted for
 * @param local - whether or not this is using the local database client or the production RDS data client
 * @param rdsParams - the parameters which will be used in the rdsData client
 * @returns {Promise<any>} - the returned data from the db client
 */
const createBearerToken = async (dbClient, formID, local, rdsParams) => {
  const token = jwt.sign(
      {
        formID
      },
      process.env.TOKEN_SECRET,
      {
        expiresIn: "1y"
      }
  );
  let data;
  if(local){
    data = await dbClient.query(
        "UPDATE templates SET bearer_token = ($1) WHERE id = ($2) RETURNING id, json_config, organization, bearer_token;",
        [token, formID]
    );
    return parseConfig(data.rows)
  }else{
    let rdsParamsCopy = {...rdsParams};
    rdsParamsCopy["sql"] = "UPDATE Templates SET bearer_token = :bearer_token WHERE id = :formID RETURNING id, json_config, organization, bearer_token;";
    rdsParamsCopy["parameters"] = [
      {
        name: "formID",
        value: {
          longValue: formID,
        },
      },
      {
        name: "bearer_token",
        value: {
          stringValue: token,
        }
      }
    ];
    const command = new ExecuteStatementCommand(rdsParamsCopy);
    data = await dbClient.send(command);
    return parseConfig(data.records)
  }

}
