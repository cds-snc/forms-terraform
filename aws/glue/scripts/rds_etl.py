import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col, from_unixtime, date_format, lit, current_timestamp, from_json, explode, explode_outer, sum as spark_sum
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, ArrayType, BooleanType
from datetime import datetime

# ------- Step 1 -------
# Initialize Glue context, and logger.
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'rds_endpoint', 'rds_db_name', 'rds_username', 'rds_password', 'rds_bucket', 's3_endpoint'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)
logger = glueContext.get_logger()

# Log the ETL Job has begun
logger.info("Starting Script for ETL of RDS data")

# ------- Step 2 -------
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

# ------- Step 3 -------
# Process the data (easy-mode)

# Get current timestamp
current_stamp = current_timestamp()

# Remove Bearer Token
redacted_df = datasource0.toDF().drop("bearerToken")
# Ensure the data types are set to timestamps for Athena.
redacted_df = redacted_df.withColumn("created_at", date_format(from_unixtime(col("created_at").cast("bigint")), "yyyy-MM-dd HH:mm:ss.SSSSSSSSS"))
redacted_df = redacted_df.withColumn("updated_at", date_format(from_unixtime(col("updated_at").cast("bigint")), "yyyy-MM-dd HH:mm:ss.SSSSSSSSS"))
# Add a timestamp column for Athena to use as a partition.
redacted_df = redacted_df.withColumn("timestamp", date_format(from_unixtime(current_stamp.cast("bigint")), "yyyy-MM-dd HH:mm:ss.SSSSSSSSS"))

# ------- Step 4 -------
# Parse the jsonConfig column to extract the values

# Add Substructures, these contain the strongly typed data that the final table will contain.
sub_element_schema = StructType([
    StructField("id", IntegerType(), True),
    StructField("type", StringType(), True),
    StructField("properties", StructType([]), True),
])

properties_schema = StructType([
    StructField("subElements", ArrayType(sub_element_schema), True),
])

element_schema = StructType([
    StructField("id", IntegerType(), True),
    StructField("type", StringType(), True),
    StructField("properties", properties_schema),
])

json_schema = StructType([
     StructField("titleEn", StringType(), True),
     StructField("titleFr", StringType(), True),
     StructField("elements", ArrayType(element_schema), True),
])

# Perform json parse for basic elements.
redacted_df = redacted_df.withColumn("parsed_json", from_json(col("jsonConfig"), json_schema))
redacted_df = redacted_df.withColumn("titleEn", col("parsed_json.titleEn"))
redacted_df = redacted_df.withColumn("titleFr", col("parsed_json.titleFr"))

# ------- Step 4.1 -------
# handle the array of elements and subElements
elements_df = (
    redacted_df.select(
        col("id"),
        explode(col("parsed_json.elements")).alias("element")
    )
) # explode the elements array

top_level_types_df = (
    elements_df
    .select(
        col("id"),
        col("element.type").alias("element_type")
    )
    .withColumn("count_value", lit(1))
) # select the top level types

sub_elements_df = (
    elements_df
    .select(
        col("id"),
        explode_outer(col("element.properties.subElements")).alias("subElement")
    )
) # explode the subElements array (if it exists)

sub_types_df = (
    sub_elements_df
    .select(
        col("id"),
        col("subElement.type").alias("element_type")
    )
    .withColumn("count_value", lit(1))
) # select the subElement types

all_types_df = top_level_types_df.unionByName(sub_types_df) # combine the top level and subElement types

grouped_counts_df = (
    all_types_df
    .filter(col("element_type").isNotNull()) # filter out null types (eg: form subelements and elements that don't have an 'element_type')
    .groupBy("id", "element_type")
    .agg(spark_sum("count_value").alias("type_count"))
) # group by id and element_type and sum the counts

pivoted_df = (
    grouped_counts_df
    .groupBy("id")
    .pivot("element_type")
    .sum("type_count")
    .na.fill(0)  # fill missing type columns with 0
) # pivot the data to have one row per id

# ------- Step 4.2 -------
# rename the columns to have _count suffix
renamed_cols_df = pivoted_df
for c in renamed_cols_df.columns:
    if c != "id":
        renamed_cols_df = renamed_cols_df.withColumnRenamed(c, f"{c}_count")

# ------- Step 4.3 -------
# join the redacted_df with the renamed_cols_df
redacted_df = (
    redacted_df
    .join(renamed_cols_df, on="id", how="left")
)

# ------- Step 5 -------
# drop the jsonConfig and parsed_json columns
redacted_df = redacted_df.drop("jsonConfig", "parsed_json")

logger.info("Produced Redacted Data Frame")

final_df = DynamicFrame.fromDF(redacted_df, glueContext, "final_df")

logger.info("Produced Final Dynamic Frame")

# ------- Step 6 -------
# Write the processed data to the target
datasink4 = glueContext.write_dynamic_frame.from_options(
    frame = final_df,
    connection_type = "s3",
    connection_options = {"path": f"s3://{args['rds_bucket']}/processed-data/"},
    format = "parquet",
    transformation_ctx = "datasink4"
)

logger.info("Data written to S3")

# ------- Step 7 -------
# Job is comitted!~  Hooray
job.commit()
