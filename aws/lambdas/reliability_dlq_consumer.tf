
#
# Dead letter queue consumer
#

resource "aws_lambda_function" "reliability_dlq_consumer" {
  function_name = "reliability-dlq-consumer"
  image_uri     = "${var.ecr_repository_url_reliability_dlq_consumer_lambda}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 300

  environment {
    variables = {
      REGION                              = var.region
      SQS_DEAD_LETTER_QUEUE_URL           = var.sqs_reliability_dead_letter_queue_id
      SQS_SUBMISSION_PROCESSING_QUEUE_URL = var.sqs_reliability_queue_id
      SNS_ERROR_TOPIC_ARN                 = var.sns_topic_alert_critical_arn
      LOCALSTACK                          = var.localstack_hosted
    }
  }

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_run_dead_letter_queue_consumer_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reliability_dlq_consumer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.reliability_dlq_lambda_trigger.arn
}

resource "aws_cloudwatch_log_group" "dead_letter_queue_consumer" {
  name              = "/aws/lambda/${aws_lambda_function.reliability_dlq_consumer.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}