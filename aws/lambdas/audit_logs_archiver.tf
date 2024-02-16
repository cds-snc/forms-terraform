data "archive_file" "audit_logs_archiver_code" {
  type        = "zip"
  source_dir  = "./code/audit_logs_archiver/dist"
  output_path = "/tmp/audit_logs_archiver_code.zip"
}

resource "aws_s3_object" "audit_logs_archiver_code" {
  bucket      = var.lambda_code_id
  key         = "audit_logs_archiver_code"
  source      = data.archive_file.audit_logs_archiver_code.output_path
  source_hash = data.archive_file.audit_logs_archiver_code.output_base64sha256
}

resource "aws_lambda_function" "audit_logs_archiver" {
  s3_bucket         = aws_s3_object.audit_logs_archiver_code.bucket
  s3_key            = aws_s3_object.audit_logs_archiver_code.key
  s3_object_version = aws_s3_object.audit_logs_archiver_code.version_id
  function_name     = "Audit_Logs_Archiver"
  role              = aws_iam_role.lambda.arn
  handler           = "audit_logs_archiver.handler"

  source_code_hash = data.archive_file.audit_logs_archiver_code.output_base64sha256
  runtime          = "nodejs18.x"
  timeout          = 900

  environment {
    variables = {
      REGION                               = var.region
      LOCALSTACK                           = var.localstack_hosted
      AUDIT_LOGS_DYNAMODB_TABLE_NAME       = var.dynamodb_audit_logs_table_name
      AUDIT_LOGS_ARCHIVE_STORAGE_S3_BUCKET = var.audit_logs_archive_storage_id
    }
  }

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_permission" "audit_logs_archiver" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.audit_logs_archiver.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.audit_logs_archiver_lambda_trigger.arn
}

resource "aws_cloudwatch_log_group" "audit_logs_archiver" {
  name              = "/aws/lambda/${aws_lambda_function.audit_logs_archiver.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}