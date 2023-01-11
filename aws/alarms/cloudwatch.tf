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

  alarm_actions = [var.sns_topic_alert_warning_arn]
  ok_actions    = [var.sns_topic_alert_ok_arn]
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
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

  alarm_actions = [var.sns_topic_alert_warning_arn]
  ok_actions    = [var.sns_topic_alert_ok_arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
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

  alarm_actions = [var.sns_topic_alert_warning_arn]

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
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

resource "aws_cloudwatch_metric_alarm" "ELB_5xx_error_warn" {
  alarm_name          = "HTTPCode_ELB_5XX_Count"
  alarm_description   = "ELB Warning - 5xx Error exceed threshold."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_alert_warning_arn]
  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
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

  alarm_actions = [var.sns_topic_alert_warning_arn]

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_cloudwatch_log_metric_filter" "reliability_error" {
  name           = "ReliabilityQueueError"
  pattern        = "Error"
  log_group_name = var.lambda_reliability_log_group_name

  metric_transformation {
    name          = "ReliabilityQueueError"
    namespace     = "forms"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "reliability_error_warn" {
  alarm_name          = "ReliabilityErrorWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.reliability_error.name
  namespace           = "forms"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  treat_missing_data  = "notBreaching"
  alarm_description   = "End User Forms Warning - An error message was detected in the Reliability Queue"

  alarm_actions = [var.sns_topic_alert_warning_arn]

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
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

  alarm_actions = [var.sns_topic_alert_warning_arn]
  dimensions = {
    QueueName = var.sqs_deadletter_queue_arn
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
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
  alarm_actions       = [var.sns_topic_alert_warning_arn]
  ok_actions          = [var.sns_topic_alert_ok_arn]


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

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
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

  alarm_actions = [var.sns_topic_alert_warning_arn]

  dimensions = {
    ResourceArn = var.lb_arn
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
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

  alarm_actions = [var.sns_topic_alert_warning_arn]

  dimensions = {
    ResourceArn = "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

#
# CodeDeploy events
#
resource "aws_cloudwatch_event_target" "codedeploy_sns" {
  target_id = "CodeDeploy_SNS"
  rule      = aws_cloudwatch_event_rule.codedeploy_sns.name
  arn       = var.sns_topic_alert_warning_arn

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

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

#
# Shield Advanced DDoS detection: ALB and Route53
#
resource "aws_cloudwatch_metric_alarm" "alb_ddos" {
  alarm_name          = "ALBDDoS"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  treat_missing_data  = "notBreaching"

  alarm_description = "DDoS detection for ALB"
  alarm_actions     = [var.sns_topic_alert_warning_arn]
  ok_actions        = [var.sns_topic_alert_ok_arn]

  dimensions = {
    ResourceArn = var.lb_arn
  }
}

resource "aws_cloudwatch_metric_alarm" "route53_ddos" {
  provider = aws.us-east-1

  alarm_name          = "Route53DDoS"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DDoSDetected"
  namespace           = "AWS/DDoSProtection"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  treat_missing_data  = "notBreaching"

  alarm_description = "DDoS detection for Route53"
  alarm_actions     = [var.sns_topic_alert_warning_us_east_arn]
  ok_actions        = [var.sns_topic_alert_ok_us_east_arn]

  dimensions = {
    ResourceArn = "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
  }
}

#
# Monitoring alarms
#

resource "aws_cloudwatch_metric_alarm" "temporary_token_generated_outside_canada_warn" {
  alarm_name          = "TemporaryTokenGeneratedOutsideCanadaWarn"
  namespace           = "AWS/WAFV2"
  metric_name         = "CountedRequests"
  statistic           = "SampleCount"
  period              = "300"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"
  treat_missing_data  = "notBreaching"
  dimensions = {
    Region = "ca-central-1"
    Rule   = "TemporaryTokenGeneratedOutsideCanada"
    WebACL = "GCForms"
  }

  alarm_description = "End User Forms Warning - A temporary token has been generated from outside Canada"
  alarm_actions     = [var.sns_topic_alert_warning_arn]
  ok_actions        = [var.sns_topic_alert_ok_arn]

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_cloudwatch_log_metric_filter" "expired_bearer_token" {
  name           = "ExpiredBearerToken"
  pattern        = "expired bearer token"
  log_group_name = var.ecs_cloudwatch_log_group_name
  metric_transformation {
    name      = "ExpiredBearerToken"
    namespace = "forms"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "expired_bearer_token" {
  alarm_name          = "ExpiredBearerToken"
  namespace           = "forms"
  metric_name         = aws_cloudwatch_log_metric_filter.expired_bearer_token.metric_transformation[0].name
  statistic           = "SampleCount"
  period              = "60"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"
  treat_missing_data  = "notBreaching"

  alarm_description = "End User Forms Warning - An expired bearer token has been used"
  alarm_actions     = [var.sns_topic_alert_warning_arn]
  ok_actions        = [var.sns_topic_alert_ok_arn]

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_cloudwatch_log_metric_filter" "generate_temporary_token_api_failure" {
  name           = "GenerateTemporaryTokenApiFailure"
  pattern        = "Failed to generate temporary token"
  log_group_name = var.ecs_cloudwatch_log_group_name
  metric_transformation {
    name      = "GenerateTemporaryTokenApiFailure"
    namespace = "forms"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "generate_temporary_token_api_failure" {
  alarm_name          = "GenerateTemporaryTokenApiFailure"
  namespace           = "forms"
  metric_name         = aws_cloudwatch_log_metric_filter.generate_temporary_token_api_failure.metric_transformation[0].name
  statistic           = "SampleCount"
  period              = "300"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "5"
  evaluation_periods  = "1"
  treat_missing_data  = "notBreaching"

  alarm_description = "End User Forms Warning - Failed to generate temporary token too many times"
  alarm_actions     = [var.sns_topic_alert_warning_arn]
  ok_actions        = [var.sns_topic_alert_ok_arn]

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_cloudwatch_log_metric_filter" "request_temporary_token_api_using_unauthorized_email_address" {
  name           = "RequestTemporaryTokenApiUsingUnauthorizedEmailAddress"
  pattern        = "\"An email address with no access to any form has been locked out\""
  log_group_name = var.ecs_cloudwatch_log_group_name
  metric_transformation {
    name      = "RequestTemporaryTokenApiUsingUnauthorizedEmailAddress"
    namespace = "forms"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "request_temporary_token_api_using_unauthorized_email_address" {
  alarm_name          = "RequestTemporaryTokenApiUsingUnauthorizedEmailAddress"
  namespace           = "forms"
  metric_name         = aws_cloudwatch_log_metric_filter.request_temporary_token_api_using_unauthorized_email_address.metric_transformation[0].name
  statistic           = "SampleCount"
  period              = "60"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"
  treat_missing_data  = "notBreaching"

  alarm_description = "End User Forms Warning - Someone tried to request a temporary token using an unauthorized email address"
  alarm_actions     = [var.sns_topic_alert_warning_arn]
  ok_actions        = [var.sns_topic_alert_ok_arn]

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_cloudwatch_log_metric_filter" "cognito_signin_exceeded" {
  name           = "CognitoSigninExceeded"
  pattern        = "\"Cognito Lockout: Password attempts exceeded\""
  log_group_name = var.ecs_cloudwatch_log_group_name

  metric_transformation {
    name          = "CognitoSigninExceeded"
    namespace     = "forms"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "cognito_signin_exceeded" {
  alarm_name          = "CognitoSigninExceeded"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = aws_cloudwatch_log_metric_filter.cognito_signin_exceeded.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.cognito_signin_exceeded.metric_transformation[0].namespace
  period              = "60"
  statistic           = "Sum"
  threshold           = "10" # this could also be adjusted depending on what we think is a good threshold
  treat_missing_data  = "notBreaching"
  alarm_description   = "Cognito - multiple failed sign-in attempts detected."

  alarm_actions = [var.sns_topic_alert_warning_arn]

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}
