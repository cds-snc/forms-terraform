#
# ECS resource usage alarms
#
resource "aws_cloudwatch_metric_alarm" "api_cpu_utilization_high_warn" {
  count = var.feature_flag_api ? 1 : 0

  alarm_name          = "API-CpuUtilizationWarn"
  alarm_description   = "API ECS Warning - High CPU usage has been detected."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.threshold_ecs_cpu_utilization_high
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.sns_topic_alert_warning_arn]
  ok_actions    = [var.sns_topic_alert_ok_arn]

  dimensions = {
    ClusterName = var.ecs_api_cluster_name
    ServiceName = var.ecs_api_service_name
  }
}

resource "aws_cloudwatch_metric_alarm" "api_memory_utilization_high_warn" {
  count = var.feature_flag_api ? 1 : 0

  alarm_name          = "API-MemoryUtilizationWarn"
  alarm_description   = "API ECS Warning - High memory usage has been detected."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.threshold_ecs_memory_utilization_high
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.sns_topic_alert_warning_arn]
  ok_actions    = [var.sns_topic_alert_ok_arn]

  dimensions = {
    ClusterName = var.ecs_api_cluster_name
    ServiceName = var.ecs_api_service_name
  }
}

resource "aws_cloudwatch_log_subscription_filter" "api_error_detection" {
  count = var.feature_flag_api ? 1 : 0

  name            = "error_detection_in_api_logs"
  log_group_name  = var.ecs_api_cloudwatch_log_group_name
  filter_pattern  = "level=error"
  destination_arn = aws_lambda_function.notify_slack.arn
}

#
# Load balancer
#
resource "aws_cloudwatch_metric_alarm" "api_lb_unhealthy_host_count" {
  count = var.feature_flag_api ? 1 : 0

  alarm_name          = "API-UnhealthyHostCount" # TODO: bump to SEV1 once this is in production
  alarm_description   = "API LB Warning - unhealthy host count >= 1 in a 1 minute period"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "1"
  evaluation_periods  = "1"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Maximum"
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.sns_topic_alert_warning_arn]
  ok_actions    = [var.sns_topic_alert_ok_arn]

  dimensions = {
    LoadBalancer = var.lb_api_arn_suffix
    TargetGroup  = var.lb_api_target_group_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "api_response_time_warn" {
  count = var.feature_flag_api ? 1 : 0

  alarm_name          = "API-ResponseTimeWarn"
  alarm_description   = "API LB Warning - The latency of response times from the API are abnormally high."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "2"
  threshold           = var.threshold_lb_response_time
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_alert_warning_arn]
  ok_actions          = [var.sns_topic_alert_ok_arn]

  metric_query {
    id          = "response_time"
    return_data = "true"
    metric {
      metric_name = "TargetResponseTime"
      namespace   = "AWS/ApplicationELB"
      period      = "60"
      stat        = "Average"
      dimensions = {
        LoadBalancer = var.lb_api_arn_suffix
        TargetGroup  = var.lb_api_target_group_arn_suffix
      }
    }
  }
}

#
# Audit Log Dead Letter Queue
#
resource "aws_cloudwatch_metric_alarm" "api_audit_log_dead_letter_queue_warn" {
  alarm_name          = "ApiAuditLogDeadLetterQueueWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  threshold           = "0"
  alarm_description   = "Detect when a message is sent to the API Audit Log Dead Letter Queue"
  alarm_actions       = [var.sns_topic_alert_warning_arn]

  metric_query {
    id          = "e1"
    expression  = "RATE(m2+m1)"
    label       = "Error Rate"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "ApproximateNumberOfMessagesVisible"
      namespace   = "AWS/SQS"
      period      = "60"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        QueueName = var.sqs_api_audit_log_deadletter_queue_arn
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "ApproximateNumberOfMessagesNotVisible"
      namespace   = "AWS/SQS"
      period      = "60"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        QueueName = var.sqs_api_audit_log_deadletter_queue_arn
      }
    }
  }
}