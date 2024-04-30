
#
# Audit Log Processing
#

resource "aws_lambda_function" "audit_logs" {
  function_name = "audit-logs"
  image_uri     = "${var.ecr_repository_url_audit_logs_lambda}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 60

  lifecycle {
    ignore_changes = [image_uri]
  }

  environment {
    variables = {
      REGION     = var.region
      LOCALSTACK = var.localstack_hosted
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/Audit_Logs"
  }

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_event_source_mapping" "audit_logs" {
  event_source_arn                   = var.sqs_audit_log_queue_arn
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
