import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import regexp_extract, col, from_unixtime, date_format, lit, current_timestamp, from_json, explode, explode_outer, sum as spark_sum, when
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, ArrayType, BooleanType
from datetime import datetime
import boto3
import json

# ------- Step 1 -------
# Initialize Glue context, and logger.
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'cloudwatch_endpoint', 's3_endpoint'])

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
    when(col("msg").isNotNull(), regexp_extract(col("msg"), r"\(formId:\s*([a-zA-Z0-9-]+)\)", 1))
)

# ------- Final Step -------
# Write the data to the S3 bucket
cloudwatch_logs = DynamicFrame.fromDF(cloudwatch_df, glueContext, "cloudwatch_logs")
glueContext.write_dynamic_frame.from_options(
    frame = cloudwatch_logs,
    connection_type = "s3",
    connection_options = {"path": f"s3://{args['rds_bucket']}/platform/gc-forms/processed-data/submissions"},
    format = "parquet"
)

job.commit()