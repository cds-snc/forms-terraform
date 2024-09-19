moved {
  from = aws_cloudwatch_metric_alarm.api_cpu_utilization_high_warn[0]
  to   = aws_cloudwatch_metric_alarm.api_cpu_utilization_high_warn
}

moved {
  from = aws_cloudwatch_metric_alarm.api_memory_utilization_high_warn[0]
  to   = aws_cloudwatch_metric_alarm.api_memory_utilization_high_warn
}

moved {
  from = aws_cloudwatch_log_subscription_filter.api_error_detection[0]
  to   = aws_cloudwatch_log_subscription_filter.api_error_detection
}

moved {
  from = aws_cloudwatch_metric_alarm.api_lb_unhealthy_host_count[0]
  to   = aws_cloudwatch_metric_alarm.api_lb_unhealthy_host_count
}

moved {
  from = aws_cloudwatch_metric_alarm.api_lb_healthy_host_count[0]
  to   = aws_cloudwatch_metric_alarm.api_lb_healthy_host_count
}

moved {
  from = aws_cloudwatch_metric_alarm.api_response_time_warn[0]
  to   = aws_cloudwatch_metric_alarm.api_response_time_warn
}

moved {
  from = aws_cloudwatch_metric_alarm.idp_cpu_utilization_high_warn[0]
  to   = aws_cloudwatch_metric_alarm.idp_cpu_utilization_high_warn
}

moved {
  from = aws_cloudwatch_metric_alarm.idp_memory_utilization_high_warn[0]
  to   = aws_cloudwatch_metric_alarm.idp_memory_utilization_high_warn
}

moved {
  from = aws_cloudwatch_log_subscription_filter.idp_error_detection[0]
  to   = aws_cloudwatch_log_subscription_filter.idp_error_detection
}

moved {
  from = aws_cloudwatch_metric_alarm.idp_response_time_warn[0]
  to   = aws_cloudwatch_metric_alarm.idp_response_time_warn
}

moved {
  from = aws_cloudwatch_metric_alarm.idp_rds_cpu_utilization[0]
  to   = aws_cloudwatch_metric_alarm.idp_rds_cpu_utilization
}

moved {
  from = aws_cloudwatch_metric_alarm.idp_bounce_rate_high[0]
  to   = aws_cloudwatch_metric_alarm.idp_bounce_rate_high
}

moved {
  from = aws_cloudwatch_metric_alarm.idp_complaint_rate_high[0]
  to   = aws_cloudwatch_metric_alarm.idp_complaint_rate_high
}