#
# Form responses archiver trigger (CRON)
#

resource "aws_cloudwatch_event_rule" "cron_4am_every_day" {
  name                = "every-day-at-4am"
  description         = "Fires every day at 4am EST"
  schedule_expression = "cron(0 9 * * ? *)" # 4 AM EST = 9 AM UTC
}

resource "aws_cloudwatch_event_target" "run_archiver_lambda_every_day" {
  rule = aws_cloudwatch_event_rule.cron_4am_every_day.name
  arn  = aws_lambda_function.archiver.arn
}