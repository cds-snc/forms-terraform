
variable "notify_api_key_secret" {
  description = "ARN of notify_api_key secret"
  type       = string
}

variable "gc_template_id" {
  description = "GC Notify send a notification templateID"
  type        = string
}

variable "database_secret_arn" {
  description = "Database connection secret arn"
  type        = string
}

variable "rds_cluster_arn" {
  description = "RDS cluster ARN"
  type        = string
}

variable "rds_db_name" {
  description = "RDS database name"
  type        = string
}

variable "sqs_reliability_queue_id" {
  description = "SQS reliability queue URL"
  type        = string
}

variable "sqs_reliability_dead_letter_queue_id" {
  description = "SQS Reliability dead letter queue URL"
  type        = string
}

variable "sqs_reliability_queue_arn" {
  description = "SQS reliability queue ARN"
  type        = string
}

variable "sqs_reprocess_submission_queue_arn" {
  description = "SQS reprocess submission queue ARN"
  type        = string
}

variable "sqs_audit_log_queue_arn" {
  description = "SQS audit log queue ARN"
  type        = string
}

variable "kms_key_cloudwatch_arn" {
  description = "CloudWatch KMS key ARN, used by the ECS task's CloudWatch log group"
  type        = string
}

variable "dynamodb_vault_arn" {
  description = "Vault DynamodDB table ARN"
  type        = string
}

variable "dynamodb_vault_table_name" {
  description = "Vault DynamodDB table name"
  type        = string
}

variable "sns_topic_alert_critical_arn" {
  description = "SNS topic ARN that critical alerts are sent to"
  type        = string
}




/////////////
