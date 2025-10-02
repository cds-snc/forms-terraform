
#
# Dead letter queue consumer
#

resource "aws_lambda_function" "reliability_dlq_consumer" {
  function_name = "reliability-dlq-consumer"
  image_uri     = "${var.ecr_repository_lambda_urls["reliability-dlq-consumer-lambda"]}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 300
  memory_size   = 256

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
      REGION                              = var.region
      SQS_DEAD_LETTER_QUEUE_URL           = var.sqs_reliability_dead_letter_queue_id
      SQS_SUBMISSION_PROCESSING_QUEUE_URL = var.sqs_reliability_queue_id
      SNS_ERROR_TOPIC_ARN                 = var.sns_topic_alert_critical_arn
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/Reliability_DLQ_Consumer"
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_run_dead_letter_queue_consumer_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reliability_dlq_consumer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.reliability_dlq_lambda_trigger.arn
}

/*
 * When implementing containerized Lambda we had to rename some of the functions.
 * In order to keep existing log groups we decided to hardcode the group name and make the Lambda write to that legacy group.
 */

resource "aws_cloudwatch_log_group" "dead_letter_queue_consumer" {
  name              = "/aws/lambda/Reliability_DLQ_Consumer"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}
