
resource "aws_lambda_function" "notification" {
  function_name = "notification"
  image_uri     = "${var.ecr_repository_lambda_urls["notification-lambda"]}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 300 # how long a lambda runs (not really a timeout :)
  memory_size   = 512

  dynamic "vpc_config" {
    for_each = local.vpc_config
    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnet_ids         = vpc_config.value.subnet_ids
    }
  }

  environment {
    variables = {
      ENVIRONMENT                      = local.env
      REGION                           = var.region
      DOMAIN                           = var.domains[0]
      NOTIFICATION_QUEUE               = var.sqs_notification_queue_arn
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
}

resource "aws_cloudwatch_log_group" "notification" {
  name              = "/aws/lambda/Notification"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}

# Wire up SQS (event source mapping) to poll for new messages and on a new message 
# invoke the lambda with the message and payload from the event
resource "aws_lambda_event_source_mapping" "notification_sqs" {
  event_source_arn = var.sqs_notification_queue_arn
  function_name    = aws_lambda_function.notification.function_name
  batch_size       = 10
  enabled          = true
}
