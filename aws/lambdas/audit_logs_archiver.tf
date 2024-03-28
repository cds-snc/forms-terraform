resource "aws_lambda_function" "audit_logs_archiver" {
  function_name = "audit-logs-archiver"
  image_uri     = "${var.ecr_repository_url_audit_logs_archiver_lambda}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 900

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