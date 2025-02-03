import sys
import json
import random
import string
import datetime
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import SparkSession
from pyspark.sql.types import (
    StructType, StructField, StringType, TimestampType, IntegerType, BooleanType, FloatType
)
from pyspark.sql.functions import lit, date_format, from_unixtime, col

# ----------------------------------------------------------------------------
# Get job parameters
# ----------------------------------------------------------------------------
# Expected arguments (example):
# --JOB_NAME <GlueJobName>
# --output_s3_path s3://your-output-bucket/your-prefix/
# --num_partitions <N>

args = getResolvedOptions(
    sys.argv,
    [
        'JOB_NAME',
        'output_s3_path',
        'num_partitions'
    ]
)

JOB_NAME = args['JOB_NAME']
OUTPUT_S3_PATH = args['output_s3_path']
NUM_PARTITIONS = int(args['num_partitions'])

# ----------------------------------------------------------------------------
# Initialize Spark/Glue contexts
# ----------------------------------------------------------------------------
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(JOB_NAME, args)

# ----------------------------------------------------------------------------
# 1. Manually define the desired schema
#    (Example: 3 columns - 'id', 'created_at', and 'jsonConfig')
# ----------------------------------------------------------------------------
manual_schema = StructType([
    StructField("id", StringType(), nullable=True),
    StructField("name", StringType(), nullable=True),
    # Timestamp Fields
    StructField("updated_at", TimestampType(), nullable=True),
    StructField("created_at", TimestampType(), nullable=True),
    StructField("timestamp", TimestampType(), nullable=True),
    # StructField("closingDate", TimestampType(), nullable=True), # Todo: Add this field, and make sure it weights to not closed.

    # ??? I dunno these ones.
    StructField("ttl", StringType(), nullable=True), # I don't know what this field is...
    # Form Fields
    StructField("jsonConfig", StringType(), nullable=True),
    StructField("securityAttribute", StringType(), nullable=True),
    StructField("isPublished", BooleanType(), nullable=True),
    StructField("formPurpose", StringType(), nullable=True), # Add special rules.
    StructField("publishFormType", StringType(), nullable=True), # Add special rules.
    StructField("publishReason", StringType(), nullable=True),
    # StructField("closedDetails", StringType(), nullable=True), #todo: Only add info when the form is closed.
])

# ----------------------------------------------------------------------------
# 2. Functions to generate random values per Spark data type
# ----------------------------------------------------------------------------
def random_string(length=10):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def random_timestamp():
    """Generate a random timestamp between 2020-01-01 and 2023-12-31."""
    start_datetime = datetime.datetime(2020, 1, 1, 0, 0, 0)
    end_datetime   = datetime.datetime(2023, 12, 31, 23, 59, 59)
    delta = end_datetime - start_datetime
    random_seconds = random.randrange(int(delta.total_seconds()))
    return start_datetime + datetime.timedelta(seconds=random_seconds)

def random_jsonConfig():
    # Generate a random JSON object with a payload size of up to 5mb.
    max_size = 5 * 1024 * 1024  # 5 MB
    json_object = {}

    while True:
        key = ''.join(random.choices(string.ascii_letters + string.digits, k=10))
        value = ''.join(random.choices(string.ascii_letters + string.digits, k=100))
        json_object[key] = value
        
        json_str = json.dumps(json_object)
        if len(json_str.encode('utf-8')) >= max_size:
            break

    return json_object

def generate_random_value(field):
    field_name = field.name
    spark_type = field.dataType

    # Special case: securityAttribute
    if field_name == "securityAttribute":
        return random.choice(["Protected A", "Unclassified", "Protected B"])
    if field_name == "jsonConfig":
        return random_jsonConfig()

    """Return a random value compatible with the given Spark data type."""
    if isinstance(spark_type, StringType):
        return random_string(10)
    elif isinstance(spark_type, TimestampType):
        return random_timestamp()
    elif isinstance(spark_type, IntegerType):
        return random.randint(0, 10_000)
    elif isinstance(spark_type, FloatType):
        return round(random.uniform(0, 100_000.0), 2)
    elif isinstance(spark_type, BooleanType):
        return random.choice([True, False])
    else:
        # Default / fallback
        return random_string(10)

# ----------------------------------------------------------------------------
# 3. Build random rows by iterating over the schema
# ----------------------------------------------------------------------------
NUM_ROWS = 1000

data_rows = []
for _ in range(NUM_ROWS):
    row_values = []
    for field in manual_schema.fields:
        row_values.append(generate_random_value(field))
    data_rows.append(tuple(row_values))

# ----------------------------------------------------------------------------
# 4. Create a Spark DataFrame from the random data
# ----------------------------------------------------------------------------
# Convert the list of tuples into an RDD
rdd = spark.sparkContext.parallelize(data_rows)

# Create the DataFrame with our manual schema
df = spark.createDataFrame(rdd, schema=manual_schema)

# ----------------------------------------------------------------------------
# 5. Convert any TimestampType columns to a string format
#    (e.g., "yyyy-MM-dd HH:mm:ss.SSSSSSSSS")
# ----------------------------------------------------------------------------
for field in manual_schema.fields:
    if isinstance(field.dataType, TimestampType):
        # Replace the column with a formatted string
        df = df.withColumn(
            field.name,
            date_format(col(field.name), "yyyy-MM-dd HH:mm:ss.SSSSSSSSS")
        )

# ----------------------------------------------------------------------------
# 6. Write the DataFrame to Parquet, partitioned as desired
# ----------------------------------------------------------------------------
df_repartitioned = df.repartition(NUM_PARTITIONS)
df_repartitioned.write.mode("overwrite").parquet(OUTPUT_S3_PATH)

# Finalize job
job.commit()
