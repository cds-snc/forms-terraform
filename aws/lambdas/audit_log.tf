
#
# Audit Log Processing
#

resource "aws_lambda_function" "audit_logs" {
  function_name = "audit-logs"
  image_uri     = "${var.ecr_repository_lambda_urls["audit-logs-lambda"]}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 60
  memory_size   = 256

  # Limit number of concurrent instances running at a time to fight against DynamoDB's API rate limiting when there is a spike in numbers of audit logs to process
  reserved_concurrent_executions = 5

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
      REGION                 = var.region
      APP_AUDIT_LOGS_SQS_ARN = var.sqs_app_audit_log_queue_arn
      API_AUDIT_LOGS_SQS_ARN = var.sqs_api_audit_log_queue_arn
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/Audit_Logs"
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_event_source_mapping" "app_audit_logs" {
  event_source_arn                   = var.sqs_app_audit_log_queue_arn
  function_name                      = aws_lambda_function.audit_logs.arn
  function_response_types            = ["ReportBatchItemFailures"]
  batch_size                         = 10
  maximum_batching_window_in_seconds = 30
  enabled                            = true
}

resource "aws_lambda_event_source_mapping" "api_audit_logs" {
  event_source_arn                   = var.sqs_api_audit_log_queue_arn
  function_name                      = aws_lambda_function.audit_logs.arn
  function_response_types            = ["ReportBatchItemFailures"]
  batch_size                         = 10
  maximum_batching_window_in_seconds = 30
  enabled                            = true
}

/*
 * When implementing containerized Lambda we had to rename some of the functions.
 * In order to keep existing log groups we decided to hardcode the group name and make the Lambda write to that legacy group.
 */

resource "aws_cloudwatch_log_group" "audit_logs" {
  name              = "/aws/lambda/Audit_Logs"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}
