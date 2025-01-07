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
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'rds_endpoint', 'rds_db_name', 'rds_username', 'rds_password', 'rds_bucket', 's3_endpoint'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)
logger = glueContext.get_logger()

# print the arguments
logger.info("Starting Script for ETL of RDS data")

# Load data from source
datasource0 = glueContext.create_dynamic_frame.from_options(
    connection_type = "postgresql",
    connection_options = {
        "url": f"jdbc:postgresql://{args['rds_endpoint']}:4510/{args['rds_db_name']}",
        "dbtable": "Template",
        "user": args['rds_username'],
        "password": args['rds_password']
    },
    transformation_ctx = "datasource0"
)

# Get current timestamp
current_stamp = current_timestamp()

# Remove Bearer Token
redacted_df = datasource0.toDF().drop("bearerToken")
# Ensure the data types are set to timestamps for Athena.
redacted_df = redacted_df.withColumn("created_at", date_format(from_unixtime(col("created_at").cast("bigint")), "yyyy-MM-dd HH:mm:ss.SSSSSSSSS"))
redacted_df = redacted_df.withColumn("updated_at", date_format(from_unixtime(col("updated_at").cast("bigint")), "yyyy-MM-dd HH:mm:ss.SSSSSSSSS"))
# Add a timestamp column for Athena to use as a partition.
redacted_df = redacted_df.withColumn("timestamp", date_format(from_unixtime(current_stamp.cast("bigint")), "yyyy-MM-dd HH:mm:ss.SSSSSSSSS"))
# Parse the jsonConfig column to extract the values
redacted_df = (
    redacted_df
    .withColumn("titleEn", get_json_object(col("jsonConfig"), '$.titleEn'))
    .withColumn("titleFr", get_json_object(col("jsonConfig"), '$.titleFr'))
    .drop("jsonConfig")  # remove this if you want to keep the original json column
)

logger.info("Produced Redacted Data Frame")

final_df = DynamicFrame.fromDF(redacted_df, glueContext, "final_df")

logger.info("Produced Final Dynamic Frame")

# Write the processed data to the target
datasink4 = glueContext.write_dynamic_frame.from_options(
    frame = final_df,
    connection_type = "s3",
    connection_options = {"path": f"s3://{args['rds_bucket']}/processed-data/"},
    format = "parquet",
    transformation_ctx = "datasink4"
)

logger.info("Data written to S3")

job.commit()
