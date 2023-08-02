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

const archiveAuditLogs = async (event, s3Client) => {
  // TODO to be removed
  console.log(`Archived expired items to S3:`);
  // Process each record in the DynamoDB stream
  for (const record of event.Records) {
    if (record.eventName === "REMOVE") {
      const expiredAuditLog = unmarshall(record.dynamodb.OldImage);
      // TODO to be removed
      console.log("Expired item details:", JSON.stringify(expiredAuditLog, null, 2));

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
      } catch (error) {
        throw new Error(`Failed to put audit logs into S3 bucket. Reason: ${error.message}.`);
      }
    }
  }
};
