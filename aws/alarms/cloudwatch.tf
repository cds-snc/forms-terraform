#
# CPU/memory high alarms
#
resource "aws_cloudwatch_metric_alarm" "forms_cpu_utilization_high_warn" {
  alarm_name          = "CpuUtilizationWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.threshold_ecs_cpu_utilization_high
  alarm_description   = "End User Forms Warning - High CPU usage has been detected."

  alarm_actions = [aws_sns_topic.alert_warning.arn]
  ok_actions    = [aws_sns_topic.alert_ok.arn]
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }
}

resource "aws_cloudwatch_metric_alarm" "forms_memory_utilization_high_warn" {
  alarm_name          = "MemoryUtilizationWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.threshold_ecs_memory_utilization_high
  alarm_description   = "End User Forms Warning - High memory usage has been detected."

  alarm_actions = [aws_sns_topic.alert_warning.arn]
  ok_actions    = [aws_sns_topic.alert_ok.arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }
}

#
# Error alarms
#
resource "aws_cloudwatch_log_metric_filter" "five_hundred_response" {
  name           = "500Response"
  pattern        = "\"HTTP/1.1 5\""
  log_group_name = var.ecs_cloudwatch_log_group_name

  metric_transformation {
    name          = "500Response"
    namespace     = "forms"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "five_hundred_response_warn" {
  alarm_name          = "500ResponseWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.five_hundred_response.name
  namespace           = "forms"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  treat_missing_data  = "notBreaching"
  alarm_description   = "End User Forms Warning - A 5xx HTML error was detected coming from the Forms."

  alarm_actions = [aws_sns_topic.alert_warning.arn]
}

resource "aws_cloudwatch_log_metric_filter" "application_error" {
  name           = "ApplicationError"
  pattern        = "Error"
  log_group_name = var.ecs_cloudwatch_log_group_name

  metric_transformation {
    name          = "ApplicationError"
    namespace     = "forms"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "application_error_warn" {
  alarm_name          = "ApplicationErrorWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.application_error.name
  namespace           = "forms"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  treat_missing_data  = "notBreaching"
  alarm_description   = "End User Forms Warning - An error message was detected in the ECS logs"

  alarm_actions = [aws_sns_topic.alert_warning.arn]
}

#
# Submissions in Dead Letter Queue
#
resource "aws_cloudwatch_metric_alarm" "forms_dead_letter_queue_warn" {
  alarm_name          = "DeadLetterQueueWarn"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  datapoints_to_alarm = "1"
  metric_name         = "ApproximateNumberOfMessagesDelayed"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_description   = "End User Forms Warning - A message has been sent to the Dead Letter Queue."

  alarm_actions = [aws_sns_topic.alert_warning.arn]
  dimensions = {
    QueueName = var.sqs_deadletter_queue_arn
  }
}

#
# Service down alarm
#
resource "aws_cloudwatch_metric_alarm" "response_time_warn" {
  alarm_name          = "ResponseTimeWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "2"
  threshold           = var.threshold_lb_response_time
  alarm_description   = "End User Forms Warning - The latency of response times from the forms are abnormally high."
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alert_warning.arn]
  ok_actions          = [aws_sns_topic.alert_ok.arn]


  metric_query {
    id          = "m1"
    return_data = "true"
    metric {
      metric_name = "TargetResponseTime"
      namespace   = "AWS/ApplicationELB"
      period      = "60"
      stat        = "Average"
      dimensions = {
        LoadBalancer = var.lb_arn_suffix
      }
    }
  }
}

#
# DDoS Alarms
#
resource "aws_cloudwatch_metric_alarm" "ddos_detected_forms_warn" {
  alarm_name          = "DDoSDetectedformsWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "End User Forms Warning - AWS has detected a DDOS attack on the End User Forms's Load Balancer"

  alarm_actions = [aws_sns_topic.alert_warning.arn]

  dimensions = {
    ResourceArn = var.lb_arn
  }
}

resource "aws_cloudwatch_metric_alarm" "ddos_detected_route53_warn" {

  alarm_name          = "DDoSDetectedRoute53Warn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "End User Forms Warning - AWS has detected a DDOS attack on the End User Forms's DNS Server"

  alarm_actions = [aws_sns_topic.alert_warning.arn]

  dimensions = {
    ResourceArn = "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
  }
}

#
# CodeDeploy events
#
resource "aws_cloudwatch_event_target" "codedeploy_sns" {
  target_id = "CodeDeploy_SNS"
  rule      = aws_cloudwatch_event_rule.codedeploy_sns.name
  arn       = aws_sns_topic.alert_warning.arn

  input_transformer {
    input_paths = {
      "status"       = "$.detail.state"
      "deploymentID" = "$.detail.deploymentId"
    }
    input_template = "\"End User Forms - CloudDeploy has registered a <status> for deployment: <deploymentID>\""
  }
}

resource "aws_cloudwatch_event_rule" "codedeploy_sns" {
  name        = "alert-on-codedeploy-status"
  description = "Alert if CodeDeploy succeeds or fails during deployment"
  event_pattern = jsonencode({
    source      = ["aws.codedeploy"],
    detail-type = ["CodeDeploy Deployment State-change Notification"],
    detail = {
      state = [
        "START",
        "SUCCESS",
        "FAILURE"
      ]
    }
  })
}
