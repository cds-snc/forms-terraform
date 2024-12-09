#
# ECS resource usage alarms
#
resource "aws_cloudwatch_metric_alarm" "idp_cpu_utilization_high_warn" {
  alarm_name          = "IdP-CpuUtilizationWarn"
  alarm_description   = "IdP ECS Warning - High CPU usage has been detected."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Maximum"
  threshold           = var.threshold_ecs_cpu_utilization_high
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.sns_topic_alert_warning_arn]
  ok_actions    = [var.sns_topic_alert_ok_arn]

  dimensions = {
    ClusterName = var.ecs_idp_cluster_name
    ServiceName = var.ecs_idp_service_name
  }
}

resource "aws_cloudwatch_metric_alarm" "idp_memory_utilization_high_warn" {
  alarm_name          = "IdP-MemoryUtilizationWarn"
  alarm_description   = "IdP ECS Warning - High memory usage has been detected."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Maximum"
  threshold           = var.threshold_ecs_memory_utilization_high
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.sns_topic_alert_warning_arn]
  ok_actions    = [var.sns_topic_alert_ok_arn]

  dimensions = {
    ClusterName = var.ecs_idp_cluster_name
    ServiceName = var.ecs_idp_service_name
  }
}

resource "aws_cloudwatch_log_subscription_filter" "idp_error_detection" {
  name            = "error_detection_in_idp_logs"
  log_group_name  = var.ecs_idp_cloudwatch_log_group_name
  filter_pattern  = local.idp_error_pattern
  destination_arn = aws_lambda_function.notify_slack.arn
}

#
# Load balancer
#
resource "aws_cloudwatch_metric_alarm" "idb_lb_unhealthy_host_count" {
  for_each = var.lb_idp_target_groups_arn_suffix

  alarm_name          = "IdP-UnhealthyHostCount-${each.key}"
  alarm_description   = "IdP LB Warning - unhealthy ${each.key} host count >= 1 in a 1 minute period"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = "1"
  evaluation_periods  = "1"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Maximum"
  treat_missing_data  = "breaching"

  alarm_actions = [var.sns_topic_alert_warning_arn]
  ok_actions    = [var.sns_topic_alert_ok_arn]

  dimensions = {
    LoadBalancer = var.lb_idp_arn_suffix
    TargetGroup  = each.value
  }
}

resource "aws_cloudwatch_metric_alarm" "idb_lb_healthy_host_count" {
  for_each = var.lb_idp_target_groups_arn_suffix

  alarm_name          = "IdP-HealthyHostCount-${each.key}" # TODO: bump to SEV1 once in production
  alarm_description   = "IdP LB Critical - no healthy ${each.key} hosts in a 1 minute period"
  comparison_operator = "LessThanThreshold"
  threshold           = "1"
  evaluation_periods  = "1"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Maximum"
  treat_missing_data  = "breaching"
  alarm_actions       = [var.sns_topic_alert_warning_arn]

  dimensions = {
    LoadBalancer = var.lb_idp_arn_suffix
    TargetGroup  = each.value
  }
}

resource "aws_cloudwatch_metric_alarm" "idp_response_time_warn" {
  alarm_name          = "IdP-ResponseTimeWarn"
  alarm_description   = "IdP LB Warning - The latency of response times from the IdP are abnormally high."
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
        LoadBalancer = var.lb_idp_arn_suffix
      }
    }
  }
}

#
# RDS
#
resource "aws_cloudwatch_metric_alarm" "idp_rds_cpu_utilization" {
  alarm_name          = "IdP-RDSCpuUtilization"
  alarm_description   = "IdP RDS Warning - high CPU use for RDS cluster in a 5 minute period"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.rds_idp_cpu_maxiumum


  alarm_actions = [var.sns_topic_alert_warning_arn]
  ok_actions    = [var.sns_topic_alert_ok_arn]

  dimensions = {
    DBClusterIdentifier = var.rds_idp_cluster_identifier
  }
}

#
# SES bounces and complaints
#
resource "aws_cloudwatch_metric_alarm" "idp_bounce_rate_high" {
  alarm_name          = "IdP-SESBounceRate"
  alarm_description   = "IdP SES Warning - bounce rate >=7% over the last 12 hours"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Reputation.BounceRate"
  namespace           = "AWS/SES"
  period              = 60 * 60 * 12
  statistic           = "Average"
  threshold           = 7 / 100
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.sns_topic_alert_warning_arn]
  ok_actions    = [var.sns_topic_alert_ok_arn]
}

resource "aws_cloudwatch_metric_alarm" "idp_complaint_rate_high" {
  alarm_name          = "IdP-SESComplaintRate"
  alarm_description   = "IdP SES Warning - complaint rate >=0.4% over the last 12 hours"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Reputation.ComplaintRate"
  namespace           = "AWS/SES"
  period              = 60 * 60 * 12
  statistic           = "Average"
  threshold           = 0.4 / 100
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.sns_topic_alert_warning_arn]
  ok_actions    = [var.sns_topic_alert_ok_arn]
}
