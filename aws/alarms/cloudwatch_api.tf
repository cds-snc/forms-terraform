#
# ECS resource usage alarms
#

resource "aws_cloudwatch_metric_alarm" "api_cpu_utilization_high_warn" {
  alarm_name          = "API-CpuUtilizationWarn"
  alarm_description   = "API ECS Warning - High CPU usage has been detected."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 120
  statistic           = "Maximum"
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
  alarm_name          = "API-MemoryUtilizationWarn"
  alarm_description   = "API ECS Warning - High memory usage has been detected."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 120
  statistic           = "Maximum"
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
  name            = "error_detection_in_api_logs"
  log_group_name  = var.ecs_api_cloudwatch_log_group_name
  filter_pattern  = "{($.level = \"warn\") || ($.level = \"error\")}"
  destination_arn = aws_lambda_function.notify_slack.arn
}

#
# Load balancer
#

resource "aws_cloudwatch_metric_alarm" "api_lb_unhealthy_host_count" {
  alarm_name        = "API-UnhealthyHostCount"
  alarm_description = "API LB Warning - unhealthy host count >= 1 in a 1 minute period"
  alarm_actions     = [var.sns_topic_alert_warning_arn]
  ok_actions        = [var.sns_topic_alert_ok_arn]

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  evaluation_periods  = 1
  treat_missing_data  = "breaching"

  metric_query {
    id = "target_group_1"

    metric {
      metric_name = "UnHealthyHostCount"
      namespace   = "AWS/ApplicationELB"
      stat        = "Maximum"
      period      = 60

      dimensions = {
        LoadBalancer = var.lb_api_arn_suffix
        TargetGroup  = var.lb_api_target_group_arn_suffix
      }
    }
  }

  metric_query {
    id = "target_group_2"

    metric {
      metric_name = "UnHealthyHostCount"
      namespace   = "AWS/ApplicationELB"
      stat        = "Maximum"
      period      = 60

      dimensions = {
        LoadBalancer = var.lb_api_arn_suffix
        TargetGroup  = var.lb_api_target_group_2_arn_suffix
      }
    }
  }

  metric_query {
    id          = "unhealthy_hosts"
    expression  = "target_group_1 + target_group_2"
    label       = "Unhealthy hosts"
    return_data = true
  }
}

resource "aws_cloudwatch_metric_alarm" "api_lb_healthy_host_count" {
  alarm_name        = "API-HealthyHostCount-SEV1" # SEV1 will prompt the on-call team to respond.
  alarm_description = "API LB Critical - no healthy hosts in a 1 minute period"
  alarm_actions     = [var.sns_topic_alert_warning_arn]

  comparison_operator = "LessThanThreshold"
  threshold           = 1
  evaluation_periods  = 1
  treat_missing_data  = "breaching"

  metric_query {
    id = "target_group_1"

    metric {
      metric_name = "HealthyHostCount"
      namespace   = "AWS/ApplicationELB"
      stat        = "Maximum"
      period      = 60

      dimensions = {
        LoadBalancer = var.lb_api_arn_suffix
        TargetGroup  = var.lb_api_target_group_arn_suffix
      }
    }
  }

  metric_query {
    id = "target_group_2"

    metric {
      metric_name = "HealthyHostCount"
      namespace   = "AWS/ApplicationELB"
      stat        = "Maximum"
      period      = 60

      dimensions = {
        LoadBalancer = var.lb_api_arn_suffix
        TargetGroup  = var.lb_api_target_group_2_arn_suffix
      }
    }
  }

  metric_query {
    id          = "healthy_hosts"
    expression  = "target_group_1 + target_group_2"
    label       = "Healthy hosts"
    return_data = true
  }
}

resource "aws_cloudwatch_metric_alarm" "api_response_time_warn" {
  alarm_name        = "API-ResponseTimeWarn"
  alarm_description = "API LB Warning - The latency of response times from the API are abnormally high."
  alarm_actions     = [var.sns_topic_alert_warning_arn]
  ok_actions        = [var.sns_topic_alert_ok_arn]

  comparison_operator = "GreaterThanThreshold"
  threshold           = var.threshold_lb_response_time
  evaluation_periods  = 5
  datapoints_to_alarm = 2
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/ApplicationELB"
  metric_name = "TargetResponseTime"
  statistic   = "Average"
  period      = 60

  dimensions = {
    LoadBalancer = var.lb_api_arn_suffix
  }
}
