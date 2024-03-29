#
# Nagware
#
data "archive_file" "nagware_code" {
  type        = "zip"
  source_dir  = "./code/nagware/dist"
  output_path = "/tmp/nagware_code.zip"
}

resource "aws_s3_object" "nagware_code" {
  bucket      = var.lambda_code_id
  key         = "nagware_code"
  source      = data.archive_file.nagware_code.output_path
  source_hash = data.archive_file.nagware_code.output_base64sha256
}

resource "aws_lambda_function" "nagware" {
  s3_bucket         = aws_s3_object.nagware_code.bucket
  s3_key            = aws_s3_object.nagware_code.key
  s3_object_version = aws_s3_object.nagware_code.version_id
  function_name     = "Nagware"
  role              = aws_iam_role.lambda.arn
  handler           = "nagware.handler"
  timeout           = 300

  source_code_hash = data.archive_file.nagware_code.output_base64sha256

  runtime = "nodejs18.x"

  environment {
    variables = {
      ENVIRONMENT               = var.env
      REGION                    = var.region
      DOMAIN                    = var.domains[0]
      DYNAMODB_VAULT_TABLE_NAME = var.dynamodb_vault_table_name
      DB_ARN                    = var.rds_cluster_arn
      DB_SECRET                 = var.database_secret_arn
      DB_NAME                   = var.rds_db_name
      NOTIFY_API_KEY            = var.notify_api_key_secret_arn
      TEMPLATE_ID               = var.gc_template_id
      LOCALSTACK                = var.localstack_hosted
      PGHOST                    = var.localstack_hosted ? "host.docker.internal" : null
      PGUSER                    = var.localstack_hosted ? "postgres" : null
      PGDATABASE                = var.localstack_hosted ? "formsDB" : null
      PGPASSWORD                = var.localstack_hosted ? "chummy" : null
    }
  }

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_run_nagware_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nagware.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.nagware_lambda_trigger.arn
}

resource "aws_cloudwatch_log_group" "nagware" {
  name              = "/aws/lambda/${aws_lambda_function.nagware.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}