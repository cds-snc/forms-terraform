resource "aws_cloudwatch_metric_alarm" "ip_added_to_block_list" {
  alarm_name          = "IpAddedToBlockList"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = var.waf_ipv4_new_blocked_ip_metric_filter_name
  namespace           = var.waf_ipv4_new_blocked_ip_metric_filter_namespace
  period              = 900 # Waf IP blocklist is updated every 15 minutes
  statistic           = "Sum"
  threshold           = 1 # Alarm as soon as any IP is added to the block list
  treat_missing_data  = "notBreaching"
  alarm_description   = "WAF - IP(s) Has been added to the dynamic block list."

  alarm_actions = [var.sns_topic_alert_warning_arn]
}

resource "aws_cloudwatch_log_subscription_filter" "waf_ipv4_blocklist_lambda_error_detection" {
  name            = "${var.waf_ipv4_blocklist_lambda_function_name}_lambda_error_detection"
  log_group_name  = var.waf_ipv4_blocklist_lambda_log_group_name
  filter_pattern  = "ERROR"
  destination_arn = aws_lambda_function.notify_slack.arn

  depends_on = [aws_lambda_permission.allow_cloudwatch_to_run_lambda]
}

resource "aws_cloudwatch_metric_alarm" "waf_ipv4_blocklist_lambda_error_detection" {
  alarm_name          = "${var.waf_ipv4_blocklist_lambda_function_name}-lambda-error-detection"
  alarm_description   = "Detected error or timeout in ${var.waf_ipv4_blocklist_lambda_function_name} lambda function (SEV2)"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.waf_ipv4_blocklist_lambda_function_name
  }

  alarm_actions = [var.sns_topic_alert_critical_arn]
}
