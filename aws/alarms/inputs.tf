variable "ecs_cloudwatch_log_group_name" {
  description = "ECS Forms CloudWatch log group name, used by app error metric alarms"
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

variable "hosted_zone_id" {
  description = "Hosted zone ID, used by DDoS alarm"
  type        = string
}

variable "kms_key_cloudwatch_arn" {
  description = "CloudWatch KMS key ARN, used by SNS topics"
  type        = string
}

variable "kms_key_cloudwatch_us_east_arn" {
  description = "CloudWatch KMS key ARN in us-east-1, used by SNS topics"
  type        = string
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

variable "sqs_deadletter_queue_arn" {
  description = "ARN of the Reliability queue's SQS Dead Letter Queue"
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
