#
# Lambda triggers
#

resource "aws_cloudwatch_event_rule" "audit_logs_archiver_lambda_trigger" {
  name                = "audit-logs-archiver-lambda-trigger"
  description         = "Fires every day at 1am EST"
  schedule_expression = "cron(0 6 * * ? *)" # 1 AM EST = 6 AM UTC
}

resource "aws_cloudwatch_event_rule" "reliability_dlq_lambda_trigger" {
  name                = "reliability-dlq-lambda-trigger"
  description         = "Fires every day at 2am EST"
  schedule_expression = "cron(0 7 * * ? *)" # 2 AM EST = 7 AM UTC
}

resource "aws_cloudwatch_event_rule" "response_archiver_lambda_trigger" {
  name                = "response-archiver-lambda-trigger"
  description         = "Fires every day at 3am EST"
  schedule_expression = "cron(0 8 * * ? *)" # 3 AM EST = 8 AM UTC
}

resource "aws_cloudwatch_event_rule" "form_archiver_lambda_trigger" {
  name                = "form-archiver-lambda-trigger"
  description         = "Fires every day at 4am EST"
  schedule_expression = "cron(0 9 * * ? *)" # 4 AM EST = 9 AM UTC
}

resource "aws_cloudwatch_event_rule" "nagware_lambda_trigger" {
  name                = "nagware-lambda-trigger"
  description         = "Fires every Tuesday, Thursday and Sunday at 5am EST"
  schedule_expression = "cron(0 10 ? * TUE,THU,SUN *)" # 5 AM EST = 10 AM UTC ; every Tuesday, Thursday and Sunday
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

resource "aws_cloudwatch_event_target" "nagware_lambda_trigger" {
  rule = aws_cloudwatch_event_rule.nagware_lambda_trigger.name
  arn  = aws_lambda_function.nagware.arn
}