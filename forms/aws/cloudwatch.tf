resource "aws_cloudwatch_log_group" "forms" {
  name       = var.cloudwatch_log_group_name
  kms_key_id = aws_kms_key.cw.arn

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

###
# AWS CloudWatch Metrics - Scaling metrics
###

resource "aws_cloudwatch_metric_alarm" "forms_cpu_utilization_high_warn" {
  alarm_name          = "CpuUtilizationWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "50"
  alarm_description   = "End User Forms Warning - High CPU usage has been detected."

  alarm_actions = [aws_sns_topic.alert_warning.arn]
  ok_actions    = [aws_sns_topic.alert_ok.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.forms.name
    ServiceName = aws_ecs_service.form_viewer.name
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
  threshold           = "50"
  alarm_description   = "End User Forms Warning - High memory usage has been detected."

  alarm_actions = [aws_sns_topic.alert_warning.arn]
  ok_actions    = [aws_sns_topic.alert_ok.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.forms.name
    ServiceName = aws_ecs_service.form_viewer.name
  }
}


###
# AWS CloudWatch Metrics - Code errors
###

resource "aws_cloudwatch_log_metric_filter" "five_hundred_response" {
  name           = "500Response"
  pattern        = "\"HTTP/1.1 5\""
  log_group_name = aws_cloudwatch_log_group.forms.name

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
  log_group_name = aws_cloudwatch_log_group.forms.name

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

###
# AWS Metrics for Submissions in Dead Letter Queue
###

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
    QueueName = aws_sqs_queue.deadletter_queue.name
  }
}

###
# AWS Metrics for Service Down Alarms
###

resource "aws_cloudwatch_metric_alarm" "response_time_warn" {
  alarm_name          = "ResponseTimeWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  datapoints_to_alarm = "2"
  threshold           = "1"
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
        LoadBalancer = aws_lb.form_viewer.arn_suffix
      }
    }
  }
}

###
# AWS CloudWatch Metrics - DDoS Alarms
###

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
    ResourceArn = aws_lb.form_viewer.arn
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
    ResourceArn = "arn:aws:route53:::hostedzone/${aws_route53_zone.form_viewer.zone_id}"
  }
}

###
# AWS CodeDeploy Events
###

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

  event_pattern = <<PATTERN
  {
    "source": [
      "aws.codedeploy"
    ],
    "detail-type": [
      "CodeDeploy Deployment State-change Notification"
    ],
    "detail": {
      "state": [
        "START",
        "SUCCESS",
        "FAILURE"
      ]
    }
  }
  PATTERN
}
