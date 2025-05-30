############################################
# Glue Job Cloudwatch
############################################

# Define the CloudWatch log group
resource "aws_cloudwatch_log_group" "glue_log_group" {
  name              = "/aws-glue/jobs/error-logs"
  retention_in_days = 365

  kms_key_id = aws_kms_key.aws_glue.arn
}

# Define the CloudWatch log stream
resource "aws_cloudwatch_log_stream" "glue_log_stream" {
  name           = "rds_glue_job_error_log_stream"
  log_group_name = aws_cloudwatch_log_group.glue_log_group.name
}

############################################
# RDS Connection
############################################

resource "aws_glue_connection" "forms_database" {
  name            = "forms-database"
  connection_type = "JDBC"

  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:postgresql://${var.rds_cluster_reader_endpoint}:${var.rds_port}/${var.rds_db_name}"
    SECRET_ID           = var.rds_connector_secret_name
  }

  physical_connection_requirements {
    availability_zone      = var.rds_cluster_instance_availability_zone
    security_group_id_list = [var.glue_job_security_group_id]
    subnet_id              = var.rds_cluster_instance_subnet_id
  }
}

############################################
# RDS Read Glue Job
############################################

# Define the local file data source
data "local_file" "glue_script" {
  filename = "${path.module}/scripts/rds_etl.py"
}

# Define the S3 bucket object resource
resource "aws_s3_object" "glue_script" {
  bucket = var.etl_bucket_name
  key    = "rds_etl.py"
  source = data.local_file.glue_script.filename
  etag   = filemd5(data.local_file.glue_script.filename)
}

# Define the Glue job resource
resource "aws_glue_job" "rds_glue_job" {
  name         = "rds_glue_job"
  role_arn     = aws_iam_role.glue_etl.arn
  connections  = [aws_glue_connection.forms_database.name]
  glue_version = "4.0"

  command {
    script_location = "s3://${aws_s3_object.glue_script.bucket}/${aws_s3_object.glue_script.key}"
    python_version  = "3"
  }

  default_arguments = {
    "--continuous-log-logGroup"          = aws_cloudwatch_log_group.glue_log_group.name
    "--continuous-log-logStreamPrefix"   = aws_cloudwatch_log_stream.glue_log_stream.name
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = "true"
    "--enable-observability-metrics"     = "true"
    "--s3_endpoint"                      = var.s3_endpoint
    "--rds_bucket"                       = var.datalake_bucket_name
    "--rds_connection_name"              = aws_glue_connection.forms_database.name
  }
  security_configuration = aws_glue_security_configuration.encryption_at_rest.name
}

# Set the trigger for the job.
resource "aws_glue_trigger" "rds_glue_trigger" {
  name     = "rds_glue_trigger"
  schedule = "cron(0 0 * * ? *)" # Daily
  type     = "SCHEDULED"
  actions {
    job_name = aws_glue_job.rds_glue_job.name
  }
}

############################################
# Historical Glue Job
############################################

# Define the local file data source
data "local_file" "historical_glue_script" {
  filename = "${path.module}/scripts/historical_etl.py"
}

# Define the local csv file.
data "local_file" "historical_csv" {
  filename = "${path.module}/data/historical_data.csv"
}

# Define the S3 bucket object resource p1
resource "aws_s3_object" "historical_glue_script" {
  bucket = var.etl_bucket_name
  key    = "historical_etl.py"
  source = data.local_file.historical_glue_script.filename
  etag   = filemd5(data.local_file.historical_glue_script.filename)
}

# Define the S3 bucket object resource p2
resource "aws_s3_object" "historical_csv" {
  bucket = var.etl_bucket_name
  key    = "historical_data.csv"
  source = data.local_file.historical_csv.filename
  etag   = filemd5(data.local_file.historical_csv.filename)
}

# Define the Glue job resource
resource "aws_glue_job" "historical_glue_job" {
  name         = "historical_glue_job"
  role_arn     = aws_iam_role.glue_etl.arn
  glue_version = "4.0"

  command {
    script_location = "s3://${aws_s3_object.historical_glue_script.bucket}/${aws_s3_object.historical_glue_script.key}"
    python_version  = "3"
  }

  default_arguments = {
    "--continuous-log-logGroup"          = aws_cloudwatch_log_group.glue_log_group.name
    "--continuous-log-logStreamPrefix"   = aws_cloudwatch_log_stream.glue_log_stream.name
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = "true"
    "--enable-observability-metrics"     = "true"
    "--s3_bucket"                        = "s3://${aws_s3_object.glue_script.bucket}/${aws_s3_object.historical_csv.key}"
    "--rds_bucket"                       = var.datalake_bucket_name
    "--historical_csv"                   = "s3://${aws_s3_object.historical_csv.bucket}/${aws_s3_object.historical_csv.key}"
  }
  security_configuration = aws_glue_security_configuration.encryption_at_rest.name
}

############################################
# Submissions Glue Job Trigger
############################################
# Define the local file data source
data "local_file" "submissions_glue_script" {
  filename = "${path.module}/scripts/submissions_etl.py"
}

# Define the S3 bucket object resource p1
resource "aws_s3_object" "submissions_glue_script" {
  bucket = var.etl_bucket_name
  key    = "submissions_etl.py"
  source = data.local_file.submissions_glue_script.filename
  etag   = filemd5(data.local_file.submissions_glue_script.filename)
}

# Define the Glue job resource
resource "aws_glue_job" "submissions_glue_job" {
  name         = "submissions_glue_job"
  role_arn     = aws_iam_role.glue_etl.arn
  glue_version = "4.0"

  command {
    script_location = "s3://${aws_s3_object.submissions_glue_script.bucket}/${aws_s3_object.submissions_glue_script.key}"
    python_version  = "3"
  }

  default_arguments = {
    "--continuous-log-logGroup"          = aws_cloudwatch_log_group.glue_log_group.name
    "--continuous-log-logStreamPrefix"   = aws_cloudwatch_log_stream.glue_log_stream.name
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = "true"
    "--enable-observability-metrics"     = "true"
    "--s3_endpoint"                      = var.datalake_bucket_name
    "--cloudwatch_endpoint"              = var.submission_cloudwatch_endpoint
    "--batch_size"                       = "daily" # full or daily
  }
  security_configuration = aws_glue_security_configuration.encryption_at_rest.name
}

# Set the trigger for the job.
resource "aws_glue_trigger" "submissions_glue_trigger" {
  name     = "submissions_glue_trigger"
  schedule = "cron(0 0 * * ? *)" # Daily
  type     = "SCHEDULED"
  actions {
    job_name = aws_glue_job.submissions_glue_job.name
  }
}