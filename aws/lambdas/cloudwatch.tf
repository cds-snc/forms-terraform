#
# Lambda triggers
#

resource "aws_cloudwatch_event_rule" "audit_logs_archiver_lambda_trigger" {
  name                = "audit-logs-archiver-lambda-trigger"
  description         = "Fires every day at 6 AM UTC"
  schedule_expression = "cron(0 6 * * ? *)" # 1 AM EST / 2 AM EDT
}

resource "aws_cloudwatch_event_rule" "reliability_dlq_lambda_trigger" {
  name                = "reliability-dlq-lambda-trigger"
  description         = "Fires every day at 7 AM UTC"
  schedule_expression = "cron(0 7 * * ? *)" # 2 AM EST / 3 AM EDT
}

resource "aws_cloudwatch_event_rule" "response_archiver_lambda_trigger" {
  name                = "response-archiver-lambda-trigger"
  description         = "Fires every day at 8 AM UTC"
  schedule_expression = "cron(0 8 * * ? *)" # 3 AM EST / 4 AM EDT
}

resource "aws_cloudwatch_event_rule" "form_archiver_lambda_trigger" {
  name                = "form-archiver-lambda-trigger"
  description         = "Fires every day at 9 AM UTC"
  schedule_expression = "cron(0 9 * * ? *)" # 4 AM EST / 5 AM EDT
}

resource "aws_cloudwatch_event_rule" "api_end_to_end_test_lambda_trigger" {
  name                = "api-end-to-end-test-lambda-trigger"
  description         = "Fires every hour"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_rule" "nagware_lambda_trigger" {
  name                = "nagware-lambda-trigger"
  description         = "Fires every day at 10 AM UTC"
  schedule_expression = "cron(0 10 * * ? *)" # 5 AM EST / 6 AM EDT
}

resource "aws_cloudwatch_event_target" "audit_logs_archiver_lambda_trigger" {
  rule = aws_cloudwatch_event_rule.audit_logs_archiver_lambda_trigger.name
  arn  = aws_lambda_function.audit_logs_archiver.arn
}

resource "aws_cloudwatch_event_target" "reliability_dlq_lambda_trigger" {
  rule = aws_cloudwatch_event_rule.reliability_dlq_lambda_trigger.name
  arn  = aws_lambda_function.reliability_dlq_consumer.arn
}

resource "aws_cloudwatch_event_target" "response_archiver_lambda_trigger" {
  rule = aws_cloudwatch_event_rule.response_archiver_lambda_trigger.name
  arn  = aws_lambda_function.response_archiver.arn
}

resource "aws_cloudwatch_event_target" "form_archiver_lambda_trigger" {
  rule = aws_cloudwatch_event_rule.form_archiver_lambda_trigger.name
  arn  = aws_lambda_function.form_archiver.arn
}

resource "aws_cloudwatch_event_target" "api_end_to_end_test_lambda_trigger" {
  rule = aws_cloudwatch_event_rule.api_end_to_end_test_lambda_trigger.name
  arn  = aws_lambda_function.api_end_to_end_test.arn
}

resource "aws_cloudwatch_event_target" "nagware_lambda_trigger" {
  rule = aws_cloudwatch_event_rule.nagware_lambda_trigger.name
  arn  = aws_lambda_function.nagware.arn
}
