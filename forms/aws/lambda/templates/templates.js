const { RDSDataClient, BatchExecuteStatementCommand } = require("@aws-sdk/client-rds-data")
const REGION = process.env.REGION;

exports.handler = async function (event) {
  const dbClient = new RDSDataClient({region: REGION});
  //if (event.httpMethod == "POST") {
    // For now querystring - will probably make this a file upload on the body
    const jsonConfig = event.queryStringParameters.json_config;

    // TODO - INSERT vs UPDATE

    const SQL = "INSERT INTO Templates (json_config) VALUES (" + jsonConfig + ")"
    
    const params = {
      database: process.env.DB_NAME,
      resourceArn: process.env.DB_ARN,
      secretArn: process.env.DB_SECRET,
      sql: SQL
    };
  
    const command = new BatchExecuteStatementCommand(params);
    try {
      const data = await dbClient.send(command);
  
      return {'data': data};
    } catch (error) {
      return {'error': error};
    }
  //} else if (event.httpMethod == "GET") {
    // get all forms from DB for now
  //  return {"message": "Hello World"};
  //}
};