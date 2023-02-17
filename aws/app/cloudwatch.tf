#
# CRON events that fires every day at different times
#

resource "aws_cloudwatch_event_rule" "cron_2am_every_day" {
  name                = "every-day-at-2am"
  description         = "Fires every day at 2am EST"
  schedule_expression = "cron(0 7 * * ? *)" # 2 AM EST = 7 AM UTC
}

resource "aws_cloudwatch_event_rule" "cron_3am_every_day" {
  name                = "every-day-at-3am"
  description         = "Fires every day at 3am EST"
  schedule_expression = "cron(0 8 * * ? *)" # 3 AM EST = 8 AM UTC
}

resource "aws_cloudwatch_event_rule" "cron_4am_every_day" {
  name                = "every-day-at-4am"
  description         = "Fires every day at 4am EST"
  schedule_expression = "cron(0 9 * * ? *)" # 4 AM EST = 9 AM UTC
}

#
# Connect CRON to Dead letter queue consumer lambda function
#

resource "aws_cloudwatch_event_target" "run_dead_letter_queue_consumer_lambda_every_day" {
  rule = aws_cloudwatch_event_rule.cron_2am_every_day.name
  arn  = aws_lambda_function.dead_letter_queue_consumer.arn
}

#
# Connect CRON to Archive form responses lambda function
#

resource "aws_cloudwatch_event_target" "run_archive_form_responses_lambda_every_day" {
  rule = aws_cloudwatch_event_rule.cron_3am_every_day.name
  arn  = aws_lambda_function.archiver.arn
}

#
# Connect CRON to Archive form templates lambda function
#

resource "aws_cloudwatch_event_target" "run_archive_form_templates_lambda_every_day" {
  rule = aws_cloudwatch_event_rule.cron_4am_every_day.name
  arn  = aws_lambda_function.archive_form_templates.arn
}