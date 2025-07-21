resource "aws_lambda_function" "audit_logs_archiver" {
  function_name = "audit-logs-archiver"
  image_uri     = "${var.ecr_repository_lambda_urls["audit-logs-archiver-lambda"]}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 900

  lifecycle {
    ignore_changes = [image_uri]
  }

  dynamic "vpc_config" {
    for_each = local.vpc_config
    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnet_ids         = vpc_config.value.subnet_ids
    }
  }

  environment {
    variables = {
      REGION                               = var.region
      AUDIT_LOGS_DYNAMODB_TABLE_NAME       = var.dynamodb_app_audit_logs_table_name
      AUDIT_LOGS_ARCHIVE_STORAGE_S3_BUCKET = var.audit_logs_archive_storage_id
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/Audit_Logs_Archiver"
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "audit_logs_archiver" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.audit_logs_archiver.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.audit_logs_archiver_lambda_trigger.arn
}

/*
 * When implementing containerized Lambda we had to rename some of the functions.
 * In order to keep existing log groups we decided to hardcode the group name and make the Lambda write to that legacy group.
 */

resource "aws_cloudwatch_log_group" "audit_logs_archiver" {
  name              = "/aws/lambda/Audit_Logs_Archiver"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}
