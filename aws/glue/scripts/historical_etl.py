import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col, from_unixtime, date_format, lit, current_timestamp
from datetime import datetime

# Initialize Glue context
args = getResolvedOptions(sys.argv, ['JOB_NAME', 's3_bucket', 'rds_bucket'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)
logger = glueContext.get_logger()

# print the arguments
logger.info("Starting Script for ETL of Historical data")
logger.info(args['s3_bucket'])

# Load the CSV from an S3 bucket as a PySpark DataFrame
historical_df = spark.read.csv(args['s3_bucket'], header=True)

# Write the processed data to the target, using the "rds_db_catalog" db, and "rds_report_processed_data" table.
datasink4 = glueContext.write_dynamic_frame.from_options(
    frame = DynamicFrame.fromDF(historical_df, glueContext, "historical_df"),
    connection_type = "s3",
    connection_options = {"path": f"s3://{args['rds_bucket']}/historical-data/"},
    format = "parquet",
    transformation_ctx = "datasink4"
)

logger.info("Data written to S3")

job.commit()
