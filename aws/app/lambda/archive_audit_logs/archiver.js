const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const { unmarshall } = require("@aws-sdk/util-dynamodb");

const REGION = process.env.REGION;
const AUDIT_LOG_ARCHIVE_S3_BUCKET = process.env.AUDIT_LOG_ARCHIVE_S3_BUCKET;

exports.handler = async (event) => {
  try {
    // TODO To be removed
    console.log("Received event:", JSON.stringify(event, null, 2));

    const s3Client = new S3Client({
      region: REGION,
      ...(process.env.AWS_SAM_LOCAL && {
        endpoint: "http://host.docker.internal:4566",
        forcePathStyle: true,
      }),
    });

    await archiveAuditLogs(event, s3Client);

    return {
      statusCode: "SUCCESS",
    };
  } catch (error) {
    console.error(
      JSON.stringify({
        level: "error",
        msg: "Failed to run audit logs Archiver.",
        error: error.message,
      })
    );

    return {
      statusCode: "ERROR",
      error: error.message,
    };
  }
};

async function archiveAuditLogs(event, s3Client) {
  const maxRetries = 2;
  const failedRecords = [];

  try {
    // Process each record in the DynamoDB stream
    for (const record of event.Records) {
      if (record.eventName === "REMOVE") {
        let retries = 0;

        while (retries <= maxRetries) {
          const expiredAuditLog = unmarshall(record.dynamodb.OldImage);
          const putObjectCommandInput = {
            Bucket: AUDIT_LOG_ARCHIVE_S3_BUCKET,
            Body: JSON.stringify(expiredAuditLog),
            // key composition up for discussion
            Key: `${new Date().toISOString().slice(0, 10)}/${expiredAuditLog.UserID}/_${
              record.eventID
            }`,
          };

          try {
            await s3Client.send(new PutObjectCommand(putObjectCommandInput));
            break; // sucessufully saved , exit retry loop
          } catch (error) {
            failedRecords.push(record.eventID);
            retries++;

            if (retries <= maxRetries) {
              console.log(
                JSON.stringify({
                  level: "warn",
                  msg: `Retrying event ${record.eventID} attemp ${retries}`,
                })
              );
              await new Promise((resolve) => setTimeout(resolve, 1000)); // wait a short time before retrying
            } else {
              console.error(
                JSON.stringify({
                  level: "error",
                  msg: `Max retries reached for event ${record.eventID}`,
                  error: error.message,
                })
              );
            }
          }
        }
      }
    }
    // log failed records
    if (Array.isArray(failedRecords) && failedRecords.length) {
      console.error(
        JSON.stringify({
          level: "error",
          msg: `failed records ${failedRecords}`,
          error: error.message,
        })
      );
    }
  } catch (error) {
    throw new Error("Failed to run Audit Logs Archiver.");
  }
}
