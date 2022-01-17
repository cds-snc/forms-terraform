const { RDSDataClient, ExecuteStatementCommand } = require("@aws-sdk/client-rds-data");
const { Client } = require('pg');
const { v4: uuidv4 } = require('uuid');

const REGION = process.env.REGION;

exports.handler = async function (event) {
  var dbClient;
  // Connect to either local or AWS db
  if (process.env.AWS_SAM_LOCAL) {
    dbClient = new Client();
    if (process.env.PGHOST && process.env.PGUSER && process.env.PGDATABASE && process.env.PGPASSWORD) {
      dbClient.connect();
    } else {
      return "Missing Environment Variables for DB config"
    }
  } else {
    dbClient = new RDSDataClient({ region: REGION });
  }

  /*
    Supported Methods:
    INSERT:
      - (Required) organizationName
    GET:
      - (Optional) organizationID. Returns all entries if not provided
    UPDATE:
      - All params are required for the first iteration of this lambda
      - (Required) organizationID
      - (Required) organizationNameEn
      - (Required) organizationNameFr
    DELETE:
      - (Required) organizationID to delete
  */
  
  const method = event.method;
  let organizationID = event.organizationID ? event.organizationID : null,
    organizationNameEn = event.organizationNameEn ? event.organizationNameEn : null,
    organizationNameFr = event.organizationNameFr ? event.organizationNameFr : null;
  
  let SQL = "",
    parameters = [];
  
  switch (method) {
    case "INSERT":
      if (organizationNameEn && organizationNameFr) {
        // generate new uuid
        organizationID = uuidv4();
        SQL = (!process.env.AWS_SAM_LOCAL) ?
          "INSERT INTO organizations (id, nameen, namefr) VALUES (:organizationID, :organizationNameEn, :organizationNameFr) RETURNING id"
          : "INSERT INTO organizations (id, nameen, namefr) VALUES ($1, $2, $3) RETURNING id";
        parameters = (!process.env.AWS_SAM_LOCAL) ? [
            {
              name: "organizationID",
              value: {
                stringValue: organizationID,
              },
            },
            {
              name: "organizationNameEn",
              value: {
                stringValue: organizationNameEn,
              },
            },
            {
              name: "organizationNameFr",
              value: {
                stringValue: organizationNameFr,
              },
            },
          ]
          : [organizationID, organizationNameEn, organizationNameFr];
      } else {
        return { error: "Missing required Name in En and Fr"}
      }
      break;
    case "GET":
      // Get a specific org if given the id, all orgs if not
      if (organizationID) {
        SQL = (!process.env.AWS_SAM_LOCAL) ?
          "SELECT * FROM organizations WHERE id = :organizationID"
        : "SELECT * FROM organizations WHERE id = ($1)";
        parameters = (!process.env.AWS_SAM_LOCAL) ? [
          {
            name: "organizationID",
            value: {
              stringValue: organizationID,
            },
          },
        ]
        : [organizationID];
      } else {
        SQL = "SELECT * FROM organizations";
      }
      break;
    case "UPDATE":
      // needs an ID and both names for now - we'll just overwrite the whole thing for an MVP
      if (organizationID && organizationNameEn && organizationNameFr) {
        SQL = (!process.env.AWS_SAM_LOCAL)
          ? "UPDATE organizations SET nameen = :organizationNameEn, namefr = :organizationNameFr WHERE id = :organizationID"
          : "UPDATE organizations SET nameen = ($1), namefr = ($2) WHERE id = ($3)";
        parameters = (!process.env.AWS_SAM_LOCAL)
        ? [
          {
            name: "organizationNameEn",
            value: {
              stringValue: organizationNameEn,
            },
          },
          {
            name: "organizationNameFr",
            value: {
              stringValue: organizationNameFr,
            },
          },
          {
            name: "organizationID",
            value: {
              stringValue: organizationID,
            },
          },
        ]
        : [organizationID, organizationNameEn, organizationNameFr];
      } else {
        return { error: "Missing required Parameter" };
      }
      break;
    case "DELETE":
      // needs the id
      if (organizationID) {
        SQL = (!process.env.AWS_SAM_LOCAL)
          ? "DELETE from organizations WHERE id = :organizationID"
          : "DELETE from organizations WHERE id = ($1)";
        parameters = (!process.env.AWS_SAM_LOCAL)
        ? [
          {
            name: "organizationID",
            value: {
              stringValue: organizationID,
            },
          },
        ]
        : [organizationID];
      } else {
        return { error: "Missing required Parameter: OrganizationID" };
      }
      break;

  }

  if (!SQL) {
    return { error: "Method not supported" };
  }

  // this is copied from templates lambda with only minor changes..
  // maybe we can reuse this code somehow?
  if (process.env.AWS_SAM_LOCAL) {
    return await dbClient.query(SQL, parameters)
      .then((data) => {
        console.log("success");
        if (data.rows && data.rows.length > 0) {
          return { data: parseResponse(data.rows) };
        }
        return { data: data };
      })
      .catch((error) => {
        console.log("error:");
        console.log(error);
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
        console.log("success");

        if (data.records && data.records.length > 0) {
          return { data: parseResponse(data.records) }
          //return { data: parseConfig(data.records) };
        }
        return { data: data };
      })
      .catch((error) => {
        console.log("error:");
        console.log(error);
        return { error: error };
      });
  }
}

const parseResponse = (records) => {
  const parsedRecords = records.map((record) => {
    let id,
      organizationNameEn,
      organizationNameFr;
    if (!process.env.AWS_SAM_LOCAL) {
      id = record[0].stringValue;
      if (record.length > 1) {
          organizationNameEn = record[1].stringValue
          organizationNameFr = record[2].stringValue
      }
    } else {
      id = record.id;
      organizationNameEn = record.nameen;
      organizationNameFr = record.namefr;
    }

    return {
      organizationID: id,
      organizationNameEn: organizationNameEn,
      organizationNameFr: organizationNameFr,
    };
  });
  return { records: parsedRecords };
}