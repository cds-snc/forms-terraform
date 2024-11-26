# Define the local file data source
data "local_file" "glue_script" {
  filename = "${path.module}/scripts/rds_etl.py"
}

# Define the S3 bucket object resource
resource "aws_s3_bucket_object" "glue_script" {
  bucket = var.etl_bucket_name
  key    = "rds_etl.py"
  source = data.local_file.glue_script.filename
}

# Define the Glue job resource
resource "aws_glue_job" "rds_glue_job" {
  name     = "rds_glue_job"
  role_arn = aws_iam_role.glue_etl.arn
  command {
    script_location = "s3://${aws_s3_bucket_object.glue_script.bucket}/${aws_s3_bucket_object.glue_script.key}"
    python_version  = "3"
  }
  default_arguments = {
    "--rds_endpoint" = var.rds_cluster_endpoint
    "--rds_db_name"  = var.rds_db_name
    "--rds_username" = var.rds_db_user
    "--rds_password" = var.rds_db_password
    "--rds_bucket" = var.datalake_bucket_arn
  }
}