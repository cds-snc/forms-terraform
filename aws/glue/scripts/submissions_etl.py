import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import regexp_extract, col, from_unixtime, date_format, current_timestamp, when
from datetime import datetime, timedelta
import boto3
import json

# ------- Step 1 -------
# Initialize Glue context, and logger.
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'cloudwatch_endpoint', 's3_endpoint', 'batch_size'])

# Create a Glue context
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Our goal is to:
# Extract the form ID and the submission ID.
# Example Message Format:
# {
#    "level": "info",
#    "msg": "MD5 hash 0a2eaa6f198e444f3fbeb272afb445e5 was calculated for submission e8064d77-715e-4f2c-89e0-a1bed2b6c0eb (formId: cm8omd5bs0006qir3hsosi0af)."
# }

log_group = args.get('cloudwatch_endpoint')

client = boto3.client('logs')

if args.get('batch_size') == 'daily':
    # Get the current time and 24 hours ago in milliseconds.
    end_time = int(datetime.utcnow().timestamp() * 1000)
    start_time = int((datetime.utcnow() - timedelta(days=1)).timestamp() * 1000)
    response = client.filter_log_events(
        logGroupName=log_group,
        filterPattern='calculated for submission',
        startTime=start_time,
        endTime=end_time
    )
else:
    response = client.filter_log_events(
        logGroupName=log_group,
        filterPattern='calculated for submission'
    )

# Extract the events; each event is expected to have a 'message' field.
log_entries = []
for event in response.get('events', []):
    message = event.get('message', '')
    # If the log is in JSON format, attempt to parse it.
    try:
        parsed = json.loads(message)
    except Exception:
        parsed = {"msg": message}
    log_entries.append(parsed)

# Create a Spark DataFrame from the list of logs.
cloudwatch_df = spark.createDataFrame(log_entries)

# Extract submission_id and form_id from the msg column.
cloudwatch_df = cloudwatch_df.withColumn(
    "submission_id",
    when(col("msg").isNotNull(), regexp_extract(col("msg"), r"submission ([a-zA-Z0-9-]+)", 1))
)
cloudwatch_df = cloudwatch_df.withColumn(
    "form_id",
    when(col("msg").isNotNull(), regexp_extract(col("msg"), r"(?i)\(formId:\s*([a-zA-Z0-9-]+)\)", 1))
)

# Drop the msg column as it's no longer needed.
cloudwatch_df = cloudwatch_df.drop("msg")

# Get current timestamp
current_stamp = current_timestamp()

# Add a timestamp column for Athena to use as a partition.
cloudwatch_df = cloudwatch_df.withColumn("timestamp", date_format(from_unixtime(current_stamp.cast("bigint")), "yyyy-MM-dd HH:mm:ss.SSSSSSSSS"))

# ------- Final Step -------
# Write the data to the S3 bucket
cloudwatch_logs = DynamicFrame.fromDF(cloudwatch_df, glueContext, "cloudwatch_logs")
glueContext.write_dynamic_frame.from_options(
    frame = cloudwatch_logs,
    connection_type = "s3",
    connection_options = {"path": f"s3://{args['s3_endpoint']}/platform/gc-forms/processed-data/submissions"},
    format = "parquet"
)

job.commit()