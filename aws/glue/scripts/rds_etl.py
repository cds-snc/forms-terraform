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
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'rds_connection_name', 'rds_bucket', 's3_endpoint'])
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
        "connectionName": args['rds_connection_name'],
        "dbtable": "Template",
    },
    transformation_ctx = "datasource0"
)

deliveryOption_df = glueContext.create_dynamic_frame.from_options(
    connection_type = "postgresql",
    connection_options = {
        "connectionName": args['rds_connection_name'],
        "dbtable": "DeliveryOption",
    },
    transformation_ctx = "delivery_option_df"
).toDF()

apiServiceAccount_df = glueContext.create_dynamic_frame.from_options(
    connection_type="postgresql",
    connection_options={
        "connectionName": args['rds_connection_name'],
        "dbtable": "ApiServiceAccount",
    },
    transformation_ctx="api_service_account_df"
).toDF()

template_to_user_df = glueContext.create_dynamic_frame.from_options(
    connection_type="postgresql",
    connection_options={
        "connectionName": args['rds_connection_name'],
        "dbtable": "TemplateUserView",
    },
    transformation_ctx="api_service_account_df"
).toDF()

# - Done the User table load...
userTable_df = glueContext.create_dynamic_frame.from_options(
    connection_type = "postgresql",
    connection_options = {
        "connectionName": args['rds_connection_name'],
        "dbtable": "User",
    },
    transformation_ctx = "userTable_df"
)

# Select only the templateId column to check existence
deliveryOption_df = deliveryOption_df.select(col("templateId").alias("id")).distinct()
apiServiceAccount_df = apiServiceAccount_df.select(col("templateId").alias("id")).distinct()

# ------- Step 3 -------
# Process the data (easy-mode)

# Get current timestamp
current_stamp = current_timestamp()

# Remove Bearer Token
redacted_df = datasource0.toDF().drop("bearerToken")

# ------- Step 3.1 -------
# Add delivery option to the redacted_df

# Perform left joins to check existence in each table
redacted_df = (
    redacted_df
    .join(deliveryOption_df.withColumn("in_delivery_option", lit(1)), on="id", how="left")
    .join(apiServiceAccount_df.withColumn("in_api_service_account", lit(1)), on="id", how="left")
)

# Assign deliveryOption based on the join results
redacted_df = redacted_df.withColumn(
    "deliveryOption",
    when(col("in_delivery_option").isNotNull() & col("in_api_service_account").isNotNull(), lit(99))  # Both tables
    .when(col("in_delivery_option").isNotNull(), lit(1))  # Only in DeliveryOption
    .when(col("in_api_service_account").isNotNull(), lit(2))  # Only in ApiServiceAccount
    .otherwise(lit(0))  # None
)

# Drop intermediate columns
redacted_df = redacted_df.drop("in_delivery_option", "in_api_service_account")

# ------- Step 3.2 -------
# the easy stuff

# Ensure the data types are set to timestamps for Athena.
redacted_df = redacted_df.withColumn("created_at", date_format(from_unixtime(col("created_at").cast("bigint")), "yyyy-MM-dd HH:mm:ss.SSSSSSSSS"))
redacted_df = redacted_df.withColumn("updated_at", date_format(from_unixtime(col("updated_at").cast("bigint")), "yyyy-MM-dd HH:mm:ss.SSSSSSSSS"))
redacted_df = redacted_df.withColumn("closingDate", date_format(from_unixtime(col("closingDate").cast("bigint")), "yyyy-MM-dd HH:mm:ss.SSSSSSSSS"))

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

brand_schema = StructType([
    StructField("name", StringType(), True),
])

json_schema = StructType([
     StructField("titleEn", StringType(), True),
     StructField("titleFr", StringType(), True),
     StructField("brand", brand_schema, True),
     StructField("elements", ArrayType(element_schema), True),
])

# Perform json parse for basic elements.
redacted_df = redacted_df.withColumn("parsed_json", from_json(col("jsonConfig"), json_schema))
redacted_df = redacted_df.withColumn("titleEn", col("parsed_json.titleEn"))
redacted_df = redacted_df.withColumn("titleFr", col("parsed_json.titleFr"))
redacted_df = redacted_df.withColumn("brand", col("parsed_json.brand.name"))

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

# ------ Step 6 -------
# handle the user and user to template tables.
redacted_user_df = userTable_df.toDF().drop("image")
# add timestamp
redacted_user_df = redacted_user_df.withColumn("timestamp", date_format(from_unixtime(current_stamp.cast("bigint")), "yyyy-MM-dd HH:mm:ss.SSSSSSSSS"))

# add timestamp
template_to_user_df = template_to_user_df.withColumn("timestamp", date_format(from_unixtime(current_stamp.cast("bigint")), "yyyy-MM-dd HH:mm:ss.SSSSSSSSS"))

# ------- Step 7 -------
# Write the processed data to the target
templateDataSink = glueContext.write_dynamic_frame.from_options(
    frame = final_df,
    connection_type = "s3",
    connection_options = {"path": f"s3://{args['rds_bucket']}/processed-data/template/"},
    format = "parquet",
    transformation_ctx = "templateDataSink"
)

userDataSink = glueContext.write_dynamic_frame.from_options(
    frame = DynamicFrame.fromDF(redacted_user_df, glueContext, "redacted_user_df"),
    connection_type = "s3",
    connection_options = {"path": f"s3://{args['rds_bucket']}/processed-data/user"},
    format = "parquet",
    transformation_ctx = "userDataSink"
)

templateToUserDataSink = glueContext.write_dynamic_frame.from_options(
    frame = DynamicFrame.fromDF(template_to_user_df, glueContext, "template_to_user_df"),
    connection_type = "s3",
    connection_options = {"path": f"s3://{args['rds_bucket']}/processed-data/templateToUser"},
    format = "parquet",
    transformation_ctx = "templateToUserDataSink"
)

logger.info("Data written to S3")

# ------- Step 7 -------
# Job is comitted!~  Hooray
job.commit()
