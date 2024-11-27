# Define the local file data source
data "local_file" "glue_script" {
  filename = "${path.module}/scripts/rds_etl.py"
}

# Define the S3 bucket object resource
resource "aws_s3_object" "glue_script" {
  bucket = var.etl_bucket_name
  key    = "rds_etl.py"
  source = data.local_file.glue_script.filename
}

# Define the CloudWatch log group
resource "aws_cloudwatch_log_group" "glue_log_group" {
  name              = "/aws-glue/jobs/error-logs"
  retention_in_days = 14
}

# Define the CloudWatch log stream
resource "aws_cloudwatch_log_stream" "glue_log_stream" {
  name           = "rds_glue_job_error_log_stream"
  log_group_name = aws_cloudwatch_log_group.glue_log_group.name
}

# Define the Glue job resource
resource "aws_glue_job" "rds_glue_job" {
  name     = "rds_glue_job"
  role_arn = aws_iam_role.glue_etl.arn
  command {
    script_location = "s3://${aws_s3_object.glue_script.bucket}/${aws_s3_object.glue_script.key}"
    python_version  = "3"
  }
  default_arguments = {
    "--continuous-log-logGroup" = aws_cloudwatch_log_group.glue_log_group.name
    "--continuous-log-logStreamPrefix"   = aws_cloudwatch_log_stream.glue_log_stream.name
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = "true"
    "--enable-observability-metrics"     = "true"
    "--s3_endpoint" = var.s3_endpoint
    "--rds_endpoint" = var.rds_cluster_endpoint
    "--rds_db_name"  = var.rds_db_name
    "--rds_username" = var.rds_db_user
    "--rds_password" = var.rds_db_password
    "--rds_bucket" = var.datalake_bucket_name
  }
}

# Set the trigger for the job.
resource "aws_glue_trigger" "rds_glue_trigger" {
  name   = "rds_glue_trigger"
  schedule = "cron(0 0 * * ? *)" # Daily
  type   = "SCHEDULED"
  actions {
    job_name = aws_glue_job.rds_glue_job.name
  }
}