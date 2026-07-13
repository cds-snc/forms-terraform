
resource "aws_lambda_function" "notification" {
  function_name = "notification"
  image_uri     = "${var.ecr_repository_lambda_urls["notification-lambda"]}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 60
  memory_size   = 256

  dynamic "vpc_config" {
    for_each = local.vpc_config
    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnet_ids         = vpc_config.value.subnet_ids
    }
  }

  environment {
    variables = {
      REGION                           = var.region
      DYNAMODB_NOTIFICATION_TABLE_NAME = var.dynamodb_notification_table_name
      NOTIFY_API_KEY                   = var.notify_api_key_secret_arn
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/Notification"
  }

  tracing_config {
    mode = "Active"
  }

  lifecycle {
    ignore_changes = [image_uri]
  }
}

resource "aws_cloudwatch_log_group" "notification" {
  name              = "/aws/lambda/Notification"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731

  tags = var.core_tags
}

resource "aws_lambda_event_source_mapping" "notification_sqs" {
  event_source_arn = var.sqs_notification_queue_arn
  function_name    = aws_lambda_function.notification.function_name

  function_response_types = ["ReportBatchItemFailures"]

  batch_size = 10
}
