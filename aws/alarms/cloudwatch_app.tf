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
  statistic           = "Maximum"
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
  statistic           = "Maximum"
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

resource "aws_cloudwatch_metric_alarm" "ELB_healthy_hosts" {
  alarm_name          = "App-HealthyHostCount-SEV1" # SEV1 will prompt the on-call team to respond.
  alarm_description   = "App LB Critical - no healthy hosts in a 1 minute period"
  comparison_operator = "LessThanThreshold"
  threshold           = "1"
  evaluation_periods  = "1"
  treat_missing_data  = "breaching"
  alarm_actions       = [var.sns_topic_alert_critical_arn]

  metric_query {
    id          = "healthy_hosts"
    expression  = "target_group_1 + target_group_2"
    label       = "Healthy hosts"
    return_data = "true"
  }

  metric_query {
    id = "target_group_1"
    metric {
      metric_name = "HealthyHostCount"
      namespace   = "AWS/ApplicationELB"
      stat        = "Maximum"
      period      = "60"
      dimensions = {
        LoadBalancer = var.lb_arn_suffix
        TargetGroup  = var.lb_target_group_1_arn_suffix
      }
    }
  }

  metric_query {
    id = "target_group_2"
    metric {
      metric_name = "HealthyHostCount"
      namespace   = "AWS/ApplicationELB"
      stat        = "Maximum"
      period      = "60"
      dimensions = {
        LoadBalancer = var.lb_arn_suffix
        TargetGroup  = var.lb_target_group_2_arn_suffix
      }
    }
  }
}

// Dead letter queue message detector

locals {
  map_of_sqs_dead_letter_queues = {
    reliability   = var.sqs_reliability_deadletter_queue_arn,
    app_audit_log = var.sqs_app_audit_log_deadletter_queue_arn,
    api_audit_log = var.sqs_api_audit_log_deadletter_queue_arn,
    file_upload   = var.sqs_file_upload_deadletter_queue_arn
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq_message_detector" {
  for_each = local.map_of_sqs_dead_letter_queues

  alarm_name          = "${each.key}DeadLetterQueueWarn"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  threshold           = "0"
  alarm_description   = "Detect when a message is sent to the ${each.key} Dead Letter Queue"
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
        QueueName = each.value
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
        QueueName = each.value
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
    FunctionName = var.lambda_vault_integrity_function_name
    Resource     = var.lambda_vault_integrity_function_name
  }
}

// Cloudwatch log subscription filters

locals {
  map_of_lambda_log_group = {
    audit_logs               = var.lambda_audit_logs_log_group_name,
    audit_logs_archiver      = var.lambda_audit_logs_archiver_log_group_name,
    form_archiver            = var.lambda_form_archiver_log_group_name,
    nagware                  = var.lambda_nagware_log_group_name,
    reliability              = var.lambda_reliability_log_group_name,
    reliability_dlq_consumer = var.lambda_reliability_dlq_consumer_log_group_name,
    response_archiver        = var.lambda_response_archiver_log_group_name,
    submission               = var.lambda_submission_log_group_name,
    vault_integrity          = var.lambda_vault_integrity_log_group_name,
    api_end_to_end_test      = var.lambda_api_end_to_end_test_log_group_name,
    file_upload_processor    = var.lambda_file_upload_processor_log_group_name,
    file_upload_cleanup      = var.lambda_file_upload_cleanup_log_group_name
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

#
# Service health: these will trigger if expected metrics thresholds are not met
#

# Submission lambda: no invocations in a given period during core hours
resource "aws_cloudwatch_metric_alarm" "healthcheck_lambda_submission_invocations_core_hours" {
  alarm_name          = "SubmissionLambdaNoInvocationsCoreHours"
  alarm_description   = "HealthCheck - no `submission` invocations in ${local.lambda_submission_expect_invocation_in_period} minutes."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  threshold           = 1
  treat_missing_data  = "breaching"

  metric_query {
    id          = "invocations_core_hours"
    label       = "Invocations (core hours)"
    expression  = "IF(((HOUR(invocations)>=9 OR HOUR(invocations)<=6)),invocations,1)" # Before 6am or after 9am (UTC) use metric, otherwise return `1`
    return_data = true
  }

  metric_query {
    id = "invocations"
    metric {
      metric_name = "Invocations"
      namespace   = "AWS/Lambda"
      period      = local.lambda_submission_expect_invocation_in_period * 60
      stat        = "Sum"
      unit        = "Count"
      dimensions = {
        FunctionName = var.lambda_submission_function_name
      }
    }
  }
}

# Nagware lambda: no invocations on a Tuesday, Thursday or Sunday
resource "aws_cloudwatch_metric_alarm" "healthcheck_lambda_nagware_invocations_schedule" {
  alarm_name          = "NagwareLambdaNoInvocationsSchedule"
  alarm_description   = "HealthCheck - no `${var.lambda_nagware_function_name}` invocations on schedule."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  threshold           = 1
  treat_missing_data  = "breaching"

  metric_query {
    id          = "invocations_schedule"
    label       = "Invocations (schedule)"
    expression  = "IF((DAY(invocations)==2 OR DAY(invocations)==4 OR DAY(invocations)==7),invocations,1)" # Tues/Thurs/Sun use metric, otherwise return `1`
    return_data = true
  }

  metric_query {
    id = "invocations"
    metric {
      metric_name = "Invocations"
      namespace   = "AWS/Lambda"
      period      = 86400
      stat        = "Sum"
      unit        = "Count"
      dimensions = {
        FunctionName = var.lambda_nagware_function_name
      }
    }
  }
}

# Form archiver: no invocations in a day
resource "aws_cloudwatch_metric_alarm" "healthcheck_lambda_form_archiver_invocations" {
  alarm_name          = "FormArchiverLambdaNoInvocations"
  alarm_description   = "HealthCheck - no `${var.lambda_form_archiver_function_name}` invocations in a day."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  threshold           = 1
  namespace           = "AWS/Lambda"
  metric_name         = "Invocations"
  statistic           = "Sum"
  period              = 86400
  treat_missing_data  = "breaching"

  dimensions = {
    FunctionName = var.lambda_form_archiver_function_name
  }
}

# Response archiver: no invocations in a day
resource "aws_cloudwatch_metric_alarm" "healthcheck_lambda_response_archiver_invocations" {
  alarm_name          = "ResponseArchiverLambdaNoInvocations"
  alarm_description   = "HealthCheck - no `${var.lambda_response_archiver_function_name}` invocations in a day."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  threshold           = 1
  namespace           = "AWS/Lambda"
  metric_name         = "Invocations"
  statistic           = "Sum"
  period              = 86400
  treat_missing_data  = "breaching"

  dimensions = {
    FunctionName = var.lambda_response_archiver_function_name
  }
}
