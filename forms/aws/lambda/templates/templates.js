const { RDSDataClient, ExecuteStatementCommand } = require("@aws-sdk/client-rds-data")
const REGION = process.env.REGION;

exports.handler = async function (event) {
  const dbClient = new RDSDataClient({region: REGION});
  const method = event.method;

  let SQL,
      parameters;
  switch (method) {
    case "INSERT":
      const json_config = "'" + JSON.stringify(event.json_config) + "'";
      SQL = "INSERT INTO Templates (json_config) VALUES (:json_config)";
      parameters = [
        {
          name: "json_config",
          typeHint: "JSON",
          value: {
            stringValue: JSON.stringify(event.json_config)
          }
        }
      ];
      break;
    case "GET":
      SQL = "SELECT * FROM Templates";
      break;
  }

  if (!SQL) {
    return {'error': "Method not supported"}
  }
   
  const params = {
    database: process.env.DB_NAME,
    resourceArn: process.env.DB_ARN,
    secretArn: process.env.DB_SECRET,
    sql: SQL,
    parameters: parameters
  };

  const command = new ExecuteStatementCommand(params);
  try {
    const data = await dbClient.send(command);
    console.log("success")
    return {'data': data};
  } catch (error) {
    console.log("error:")
    console.log(error);
    return {'error': error};
  }
};
