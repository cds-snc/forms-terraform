resource "aws_cloudwatch_log_metric_filter" "ip_added_to_block_list" {
  name           = "IpAddedToBlockList"
  pattern        = "\"Updated WAF IP set with\""
  log_group_name = var.waf_ip_blocking_cloudwatch_log_group_name

  metric_transformation {
    name          = "IpAddedToBlockList"
    namespace     = "forms"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "ip_added_to_block_list" {
  alarm_name          = "IpAddedToBlockList"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.ip_added_to_block_list.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.ip_added_to_block_list.metric_transformation[0].namespace
  period              = 900 # Waf IP blocklist is updated every 15 minutes
  statistic           = "Sum"
  threshold           = 1 # Alarm as soon as any IP is added to the block list
  treat_missing_data  = "notBreaching"
  alarm_description   = "WAF - IP(s) Has been added to the dynamic block list."

  alarm_actions = [var.sns_topic_alert_warning_arn]
}