resource "aws_cloudwatch_event_rule" "vpn_lambda_trigger" {
  name                = "vpn-lambda-trigger"
  description         = "Fires every 2 hours"
  schedule_expression = "rate(2 hours)" # Every 2 hours
}

resource "aws_cloudwatch_event_target" "vpn_lambda_trigger" {
  rule = aws_cloudwatch_event_rule.vpn_lambda_trigger.name
  arn  = aws_lambda_function.vpn_lambda.arn
}

