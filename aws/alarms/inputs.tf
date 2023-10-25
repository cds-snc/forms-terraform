variable "kms_key_cloudwatch_arn" {
  description = "CloudWatch KMS key ARN used to encrypt the logs"
  type        = string
}

variable "ecs_cloudwatch_log_group_name" {
  description = "ECS Forms CloudWatch log group name, used by app error metric alarms"
  type        = string
}

variable "lambda_reliability_log_group_name" {
  description = "Reliability Queues CloudWatch log group name"
  type        = string
}

variable "lambda_submission_log_group_name" {
  description = "Submission Lambda CloudWatch log group name"
  type        = string
}

variable "lambda_archiver_log_group_name" {
  description = "Response Archiver Lambda CloudWatch log group name"
  type        = string
}

variable "lambda_dlq_consumer_log_group_name" {
  description = "DQL Consumer CloudWatch log group name"
  type        = string
}

variable "lambda_template_archiver_log_group_name" {
  description = "Template Archiver Lambda CloudWatch log group name"
  type        = string
}

variable "lambda_audit_log_group_name" {
  description = "Audit Log Lambda CloudWatch log group name"
  type        = string
}

variable "lambda_nagware_log_group_name" {
  description = "Nagware Lambda CloudWatch log group name"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name, used by CPU/memory threshold alarms"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name, used by CPU/memory threshold alarms"
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

variable "slack_webhook" {
  description = "The Slack webhook path that notifications are sent to (posted to https://hooks.slack.com/)"
  type        = string
  sensitive   = true
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