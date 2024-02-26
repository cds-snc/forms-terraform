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
}

resource "aws_cloudwatch_metric_alarm" "UnHealthyHostCount" {
  alarm_name          = "UnHealthyHostCount-SEV1" # SEV1 will prompt the on-call team to respond.
  alarm_description   = "ELB Health Check - UnHealthyHostCount exceed threshold."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1" # Evaluate once
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60" # Every minute
  statistic           = "SampleCount" # use the number of data points during the period
  threshold           = "1" # If there is at least one unhealthy host
  treat_missing_data  = "notBreaching" # don't alarm if there's no data
  alarm_actions       = [var.sns_topic_alert_critical_arn]
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
}

resource "aws_cloudwatch_metric_alarm" "vault_data_integrity_check_lambda_iterator_age" {
  alarm_name = "Vault data integrity check lambda iterator age"

  namespace           = "AWS/Lambda"
  metric_name         = "IteratorAge"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "90000" // 90 seconds (Lambda consumes events every 60 seconds if low traffic. Adding 30 seconds on top of that for the processing time of that Lambda)
  period              = "60"
  evaluation_periods  = "2"
  treat_missing_data  = "notBreaching"
  alarm_description   = "Warning - Vault data integrity check lambda is unable to keep up with the amount of events sent by the Vault DynamoDB stream"
  alarm_actions       = [var.sns_topic_alert_warning_arn]
  ok_actions          = [var.sns_topic_alert_ok_arn]

  dimensions = {
    FunctionName = var.lambda_vault_data_integrity_check_function_name
    Resource     = var.lambda_vault_data_integrity_check_function_name
  }
}

// Cloudwatch log subscription filters

locals {
  map_of_lambda_log_group = {
    reliability                = var.lambda_reliability_log_group_name,
    submission                 = var.lambda_submission_log_group_name,
    response_archiver          = var.lambda_response_archiver_log_group_name,
    template_archiver          = var.lambda_template_archiver_log_group_name,
    dlq_consumer               = var.lambda_dlq_consumer_log_group_name,
    audit_log                  = var.lambda_audit_log_group_name,
    nagware                    = var.lambda_nagware_log_group_name,
    vault_data_integrity_check = var.lambda_vault_data_integrity_check_log_group_name,
    audit_logs_archiver        = var.lambda_audit_logs_archiver_group_name
  }
}

/*
 * Dynamic Stream to Lambda
 * (see comment in the Lambda timeout detection section)
 */

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

resource "aws_cloudwatch_log_subscription_filter" "lambda_error_detection" {
  for_each        = local.map_of_lambda_log_group
  name            = "error_detection_in_${each.key}_lambda_logs"
  log_group_name  = each.value
  filter_pattern  = "{($.level = \"warn\") || ($.level = \"error\")}"
  destination_arn = aws_lambda_function.notify_slack.arn
}

/*
 * Lambda timeout detection
 * Note: We used the second and final lambda subscription filter to detect function time out.
 * If we ever need to create a new subscription filter we will have to rework the way we parse logs to extract errors and time out logs.
 */

resource "aws_cloudwatch_log_subscription_filter" "lambda_timeout_detection" {
  for_each        = local.map_of_lambda_log_group
  name            = "timeout_detection_in_${each.key}_lambda_logs"
  log_group_name  = each.value
  filter_pattern  = "Task timed out"
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

// Monitor for Cognito sign-ins from outside of Canada within a 1 minute period
resource "aws_cloudwatch_metric_alarm" "cognito_login_outside_canada_warn" {
  alarm_name          = "AWSCognitoLoginOutsideCanadaAlarm"
  namespace           = "AWS/WAFV2"
  metric_name         = "CountedRequests"
  statistic           = "SampleCount"
  period              = "60" // 1 minute
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  evaluation_periods  = "1"            // number of datapoints to evaluate
  treat_missing_data  = "notBreaching" // don't alarm if there's no data

  alarm_actions = [var.sns_topic_alert_warning_arn]

  dimensions = {
    Rule   = "AWSCognitoLoginOutsideCanada"
    WebACL = "GCForms"
    Region = "ca-central-1"
  }

  alarm_description = "Forms: A sign-in by a forms owner has been detected from outside of Canada."
}
