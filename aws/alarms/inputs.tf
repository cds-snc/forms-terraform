variable "kms_key_cloudwatch_arn" {
  description = "CloudWatch KMS key ARN used to encrypt the logs"
  type        = string
}

variable "ecs_cloudwatch_log_group_name" {
  description = "ECS App Forms CloudWatch log group name, used by app error metric alarms"
  type        = string
}

variable "ecs_idp_cloudwatch_log_group_name" {
  description = "ECS IdP CloudWatch log group name, used by IdP error metric alarms"
  type        = string
}

variable "lambda_audit_logs_log_group_name" {
  description = "Audit Log Lambda CloudWatch log group name"
  type        = string
}

variable "lambda_audit_logs_archiver_log_group_name" {
  description = "Audit logs archiver Lambda CloudWatch log group name"
  type        = string
}

variable "lambda_form_archiver_function_name" {
  description = "Form Archiver function name"
  type        = string
}

variable "lambda_form_archiver_log_group_name" {
  description = "Template Archiver Lambda CloudWatch log group name"
  type        = string
}

variable "lambda_nagware_function_name" {
  description = "Nagware Lambda function name"
  type        = string
}

variable "lambda_nagware_log_group_name" {
  description = "Nagware Lambda CloudWatch log group name"
  type        = string
}

variable "lambda_reliability_log_group_name" {
  description = "Reliability Queues CloudWatch log group name"
  type        = string
}

variable "lambda_reliability_dlq_consumer_log_group_name" {
  description = "DQL Consumer CloudWatch log group name"
  type        = string
}

variable "lambda_response_archiver_function_name" {
  description = "Response Archiver function name"
  type        = string
}

variable "lambda_response_archiver_log_group_name" {
  description = "Response Archiver Lambda CloudWatch log group name"
  type        = string
}

variable "lambda_submission_expect_invocation_in_period" {
  description = "Submission Lambda period (minutes) during which it is expected at least one function invocation will occur.  This is used for the healthcheck alarms."
  type        = number
}

variable "lambda_submission_function_name" {
  description = "Submission Lambda function name"
  type        = string
}

variable "lambda_submission_log_group_name" {
  description = "Submission Lambda CloudWatch log group name"
  type        = string
}

variable "lambda_vault_integrity_log_group_name" {
  description = "Vault data integrity check Lambda CloudWatch log group name"
  type        = string
}

variable "lambda_vault_integrity_function_name" {
  description = "Vault data integrity check lambda function name"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name, used by CPU/memory threshold alarms"
  type        = string
}

variable "ecs_idp_cluster_name" {
  description = "IdP's ECS cluster name, used by CPU/memory threshold alarms"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name, used by CPU/memory threshold alarms"
  type        = string
}

variable "ecs_idp_service_name" {
  description = "IdP's ECS service name, used by CPU/memory threshold alarms"
  type        = string
}

variable "hosted_zone_ids" {
  description = "Hosted zone ID, used by DDoS alarm"
  type        = list(string)
}

variable "lb_arn" {
  description = "Load balancer ARN, used by DDoS alarms"
  type        = string
}

variable "lb_arn_suffix" {
  description = "Load balancer ARN suffix, used by response time alarms"
  type        = string
}

variable "lb_idp_arn_suffix" {
  description = "IdP's load balancer ARN suffix, used by response time alarms"
  type        = string
}

variable "lb_target_group_1_arn_suffix" {
  description = "Load balancer target group 1 ARN suffix, used by response time alarms"
  type        = string
}

variable "lb_target_group_2_arn_suffix" {
  description = "Load balancer target group 2 ARN suffix, used by response time alarms"
  type        = string
}

variable "lb_idp_target_group_arn_suffix" {
  description = "IdP's load balancer target group ARN suffix, used by response time alarms"
  type        = string
}

variable "slack_webhook" {
  description = "The Slack webhook path that notifications are sent to (posted to https://hooks.slack.com/)"
  type        = string
  sensitive   = true
}

variable "opsgenie_api_key" {
  description = "The OpsGenie api key to be used when calling https://api.opsgenie.com/v2/alerts"
  type        = string
  sensitive   = true
}

variable "rds_cluster_identifier" {
  description = "RDS cluster identifier used for alarms and dashboards"
  type        = string
}

variable "rds_idp_cluster_identifier" {
  description = "The IdP's RDS cluster identifier used for alarms and dashboards"
  type        = string
}

variable "rds_idp_cpu_maxiumum" {
  description = "The maximum CPU utilization percentage threshold for the IdP's RDS cluster"
  type        = number

}

variable "sqs_reliability_deadletter_queue_arn" {
  description = "ARN of the Reliability queue's SQS Dead Letter Queue"
  type        = string
}

variable "sqs_audit_log_deadletter_queue_arn" {
  description = "ARN of the Audit Log queue's SQS Dead Letter Queue"
  type        = string
}

variable "threshold_ecs_cpu_utilization_high" {
  description = "ECS cluster CPU average use threshold, above which an alarm is triggered (4 minute period)"
  type        = string
}

variable "threshold_ecs_memory_utilization_high" {
  description = "ECS cluster memory average use threshold, above which an alarm is triggered (4 minute period)"
  type        = string
}

variable "threshold_lb_response_time" {
  description = "Load balancer response time, in seconds, above which an alarm is triggered (10 minute period)"
  type        = string
}

variable "sns_topic_alert_critical_arn" {
  description = "SNS topic ARN that critical alerts are sent to"
  type        = string
}

variable "sns_topic_alert_warning_arn" {
  description = "SNS topic ARN that warning alerts are sent to"
  type        = string
}

variable "sns_topic_alert_ok_arn" {
  description = "SNS topic ARN that ok alerts are sent to"
  type        = string
}

variable "sns_topic_alert_warning_us_east_arn" {
  description = "SNS topic ARN that warning alerts are sent to (US East)"
  type        = string
}

variable "sns_topic_alert_ok_us_east_arn" {
  description = "SNS topic ARN that ok alerts are sent to (US East)"
  type        = string
}

variable "ecr_repository_url_notify_slack_lambda" {
  description = "URL of the Notify Slack Lambda ECR"
  type        = string
}
