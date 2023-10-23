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

#
# Submissions Dead Letter Queue
#
resource "aws_cloudwatch_metric_alarm" "reliability_dead_letter_queue_warn" {
  alarm_name          = "ReliabilityDeadLetterQueueWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  threshold           = "0"
  alarm_description   = "Detect when a message is sent to the Reliability Dead Letter Queue"
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
        QueueName = var.sqs_reliability_deadletter_queue_arn
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
        QueueName = var.sqs_reliability_deadletter_queue_arn
      }
    }
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

#
# Audit Log Dead Letter Queue
#
resource "aws_cloudwatch_metric_alarm" "audit_log_dead_letter_queue_warn" {
  alarm_name          = "AuditLogDeadLetterQueueWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  threshold           = "0"
  alarm_description   = "Detect when a message is sent to the Audit Log Dead Letter Queue"
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
        QueueName = var.sqs_audit_log_deadletter_queue_arn
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
        QueueName = var.sqs_audit_log_deadletter_queue_arn
      }
    }
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

  count               = length(var.hosted_zone_ids)
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
    ResourceArn = var.hosted_zone_ids[count.index]
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
  count    = length(var.hosted_zone_ids)

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
    ResourceArn = var.hosted_zone_ids[count.index]
  }
}

#
# Monitoring alarms
#

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
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.cognito_signin_exceeded.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.cognito_signin_exceeded.metric_transformation[0].namespace
  period              = 60
  statistic           = "Sum"
  threshold           = 5 # this could also be adjusted depending on what we think is a good threshold
  treat_missing_data  = "notBreaching"
  alarm_description   = "Cognito - multiple failed sign-in attempts detected."

  alarm_actions = [var.sns_topic_alert_warning_arn]

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_cloudwatch_log_metric_filter" "twoFa_verification_exceeded" {
  name           = "2FAVerificationExceeded"
  pattern        = "\"2FA Lockout: Verification code attempts exceeded\""
  log_group_name = var.ecs_cloudwatch_log_group_name

  metric_transformation {
    name          = "2FAVerificationExceeded"
    namespace     = "forms"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "twoFa_verification_exceeded" {
  alarm_name          = "2FAVerificationExceeded"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.twoFa_verification_exceeded.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.twoFa_verification_exceeded.metric_transformation[0].namespace
  period              = 60
  statistic           = "Sum"
  threshold           = 2 # this could also be adjusted depending on what we think is a good threshold
  treat_missing_data  = "notBreaching"
  alarm_description   = "2FA - multiple failed verification attempts detected. User has been locked out (see audit logs)."

  alarm_actions = [var.sns_topic_alert_warning_arn]

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

// Dynamic Stream to Lambda

resource "aws_cloudwatch_log_subscription_filter" "forms_unhandled_error_steam" {
  depends_on      = [aws_lambda_permission.allow_cloudwatch_to_run_lambda]
  name            = "forms_unhandled_error_stream"
  log_group_name  = var.ecs_cloudwatch_log_group_name
  filter_pattern  = "Error -level" # Do not catch JSON formatted logs with `level` property because those will be handled by the filters below
  destination_arn = aws_lambda_function.notify_slack.arn
}

resource "aws_cloudwatch_log_subscription_filter" "forms_app_log_stream" {
  name            = "forms_app_log_stream"
  log_group_name  = var.ecs_cloudwatch_log_group_name
  filter_pattern  = "{($.level = \"warn\") || ($.level = \"error\")}"
  destination_arn = aws_lambda_function.notify_slack.arn
}

resource "aws_cloudwatch_log_subscription_filter" "reliability_log_stream" {
  name            = "reliability_log_stream"
  log_group_name  = var.lambda_reliability_log_group_name
  filter_pattern  = "{($.level = \"warn\") || ($.level = \"error\")}"
  destination_arn = aws_lambda_function.notify_slack.arn
}

resource "aws_cloudwatch_log_subscription_filter" "submission_log_stream" {
  name            = "submission_log_stream"
  log_group_name  = var.lambda_submission_log_group_name
  filter_pattern  = "{($.level = \"warn\") || ($.level = \"error\")}"
  destination_arn = aws_lambda_function.notify_slack.arn
}

resource "aws_cloudwatch_log_subscription_filter" "archiver_log_stream" {
  name            = "archiver_log_stream"
  log_group_name  = var.lambda_archiver_log_group_name
  filter_pattern  = "{($.level = \"warn\") || ($.level = \"error\")}"
  destination_arn = aws_lambda_function.notify_slack.arn
}
resource "aws_cloudwatch_log_subscription_filter" "dlq_consumer_log_stream" {
  name            = "dql_consumer_log_stream"
  log_group_name  = var.lambda_dlq_consumer_log_group_name
  filter_pattern  = "{($.level = \"warn\") || ($.level = \"error\")}"
  destination_arn = aws_lambda_function.notify_slack.arn
}
resource "aws_cloudwatch_log_subscription_filter" "template_archiver_log_stream" {
  name            = "template_archiver_log_stream"
  log_group_name  = var.lambda_template_archiver_log_group_name
  filter_pattern  = "{($.level = \"warn\") || ($.level = \"error\")}"
  destination_arn = aws_lambda_function.notify_slack.arn
}
resource "aws_cloudwatch_log_subscription_filter" "audit_log_stream" {
  name            = "audit_log_stream"
  log_group_name  = var.lambda_audit_log_group_name
  filter_pattern  = "{($.level = \"warn\") || ($.level = \"error\")}"
  destination_arn = aws_lambda_function.notify_slack.arn
}
resource "aws_cloudwatch_log_subscription_filter" "nagware_log_stream" {
  name            = "nagware_log_stream"
  log_group_name  = var.lambda_nagware_log_group_name
  filter_pattern  = "{($.level = \"warn\") || ($.level = \"error\")}"
  destination_arn = aws_lambda_function.notify_slack.arn
}

resource "aws_cloudwatch_log_subscription_filter" "vault_data_integrity_check_log_stream" {
  name            = "vault_data_integrity_check_log_stream"
  log_group_name  = var.lambda_vault_data_integrity_check_log_group_name
  filter_pattern  = "{($.level = \"warn\") || ($.level = \"error\")}"
  destination_arn = aws_lambda_function.notify_slack.arn
}

// Allow Cloudwatch filters to trigger Lambda

resource "aws_lambda_permission" "allow_cloudwatch_to_run_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify_slack.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "arn:aws:logs:ca-central-1:${var.account_id}:log-group:*:*"
}