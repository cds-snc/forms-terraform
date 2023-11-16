
data "archive_file" "reliability_code" {
  type        = "zip"
  source_dir  = "./code/reliability/dist/"
  output_path = "/tmp/reliability_code.zip"

}

resource "aws_s3_bucket_object" "reliability_code" {
  bucket      = var.lambda_code_id
  key         = "reliability_code"
  source      = data.archive_file.reliability_code.output_path
  source_hash = data.archive_file.reliability_code.output_base64sha256
}

resource "aws_lambda_function" "reliability" {
  s3_bucket         = aws_s3_bucket_object.reliability_code.bucket
  s3_key            = aws_s3_bucket_object.reliability_code.key
  s3_object_version = aws_s3_bucket_object.reliability_code.version_id
  function_name     = "Reliability"
  role              = aws_iam_role.lambda.arn
  handler           = "reliability.handler"
  timeout           = 300

  source_code_hash = data.archive_file.reliability_code.output_base64sha256

  runtime = "nodejs18.x"

  environment {
    variables = {
      ENVIRONMENT    = var.env
      REGION         = var.region
      NOTIFY_API_KEY = var.notify_api_key_secret
      TEMPLATE_ID    = var.gc_template_id
      DB_ARN         = var.rds_cluster_arn
      DB_SECRET      = var.database_secret_arn
      DB_NAME        = var.rds_db_name
      LOCALSTACK     = var.localstack_hosted
      PGHOST         = var.localstack_hosted ? "host.docker.internal" : null
      PGUSER         = var.localstack_hosted ? "postgres" : null
      PGDATABASE     = var.localstack_hosted ? "formsDB" : null
      PGPASSWORD     = var.localstack_hosted ? "chummy" : null

    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_lambda_event_source_mapping" "reliability" {
  event_source_arn = var.sqs_reliability_queue_arn
  function_name    = aws_lambda_function.reliability.arn
  batch_size       = 1
  enabled          = true
}

resource "aws_lambda_event_source_mapping" "reprocess_submission" {
  event_source_arn = var.sqs_reprocess_submission_queue_arn
  function_name    = aws_lambda_function.reliability.arn
  batch_size       = 1
  enabled          = true
}

resource "aws_cloudwatch_log_group" "reliability" {
  name              = "/aws/lambda/${aws_lambda_function.reliability.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 90
}

