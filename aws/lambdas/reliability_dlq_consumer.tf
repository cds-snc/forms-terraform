
#
# Dead letter queue consumer
#

data "archive_file" "reliability_dlq_consumer_code" {
  type        = "zip"
  source_dir  = "./code/reliability_dlq_consumer/dist"
  output_path = "/tmp/reliability_dlq_consumer_code.zip"
}

resource "aws_s3_object" "reliability_dlq_consumer_code" {
  bucket      = var.lambda_code_id
  key         = "reliability_dlq_consumer_code"
  source      = data.archive_file.reliability_dlq_consumer_code.output_path
  source_hash = data.archive_file.reliability_dlq_consumer_code.output_base64sha256
}




resource "aws_lambda_function" "reliability_dlq_consumer" {
  s3_bucket         = aws_s3_object.reliability_dlq_consumer_code.bucket
  s3_key            = aws_s3_object.reliability_dlq_consumer_code.key
  s3_object_version = aws_s3_object.reliability_dlq_consumer_code.version_id
  function_name     = "Reliability_DLQ_Consumer"
  role              = aws_iam_role.lambda.arn
  handler           = "dead_letter_queue_consumer.handler"

  source_code_hash = data.archive_file.reliability_dlq_consumer_code.output_base64sha256
  runtime          = "nodejs18.x"
  timeout          = 300

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
  source_arn    = aws_cloudwatch_event_rule.cron_2am_every_day.arn
}

resource "aws_cloudwatch_log_group" "dead_letter_queue_consumer" {
  name              = "/aws/lambda/${aws_lambda_function.reliability_dlq_consumer.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 90
}