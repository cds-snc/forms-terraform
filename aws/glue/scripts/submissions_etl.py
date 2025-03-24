import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col, from_unixtime, date_format, lit, current_timestamp, from_json, explode, explode_outer, sum as spark_sum, when
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, ArrayType, BooleanType
from datetime import datetime

# ------- Step 1 -------
# Initialize Glue context, and logger.
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'cloudwatch_endpoint', 's3_endpoint'])

# Create a Glue context
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# ------- Step 2 -------
# Read the data from the Cloud Watch Logs
cloudwatch_logs = glueContext.create_dynamic_frame.from_options(
    connection_type = "s3",
    format="json",
    connection_options = {
        "paths": [ args['cloudwatch_endpoint'] ],
    }
)

# ------- Step 3 -------
# Look for the submission logs : Response submitted for Form ID: 123456
# Extract the form ID and the response status
cloudwatch_logs = cloudwatch_logs.toDF()
cloudwatch_logs = cloudwatch_logs.withColumn("form_id", col("message").substr(31, 6))
cloudwatch_logs = cloudwatch_logs.withColumn("status", when(col("message").contains("Response submitted"), "Submitted").otherwise("Failed"))

# ------- Step 4 -------
# Aggregate the data by form ID and status
cloudwatch_logs = cloudwatch_logs.groupBy("form_id", "status").count()

# ------- Step 5 -------
# Write the data to the S3 bucket
cloudwatch_logs = DynamicFrame.fromDF(cloudwatch_logs, glueContext, "cloudwatch_logs")
glueContext.write_dynamic_frame.from_options(
    frame = cloudwatch_logs,
    connection_type = "s3",
    connection_options = {"path": f"s3://{args['rds_bucket']}/platform/gc-forms/processed-data/submissions"},
    format = "parquet"
)

job.commit()