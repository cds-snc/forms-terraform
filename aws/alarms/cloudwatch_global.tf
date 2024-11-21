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