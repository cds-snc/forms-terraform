variable "notify_api_key_secret_arn" {
  description = "GC Notify API key arn"
  type        = string
  sensitive   = true
}

variable "gc_template_id" {
  description = "GC Notify send a notification templateID"
  type        = string
}

variable "database_secret_arn" {
  description = "Database connection secret arn"
  type        = string
}

variable "database_url_secret_arn" {
  description = "Database URL secret version ARN, used by the ECS task"
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

variable "sqs_app_audit_log_queue_arn" {
  description = "SQS audit log queue ARN"
  type        = string
}

variable "sqs_api_audit_log_queue_arn" {
  description = "SQS Api audit log queue ARN"
  type        = string
}

variable "kms_key_cloudwatch_arn" {
  description = "CloudWatch KMS key ARN, used by the ECS task's CloudWatch log group"
  type        = string
}

variable "kms_key_dynamodb_arn" {
  description = "DynamoDB KMS key ARN, used by the Lambdas"
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

variable "dynamodb_vault_stream_arn" {
  description = "Vault DynamoDB stream ARN"
  type        = string
}

variable "dynamodb_relability_queue_arn" {
  description = "Reliability queue DynamodDB table ARN"
  type        = string
}

variable "dynamodb_app_audit_logs_arn" {
  description = "Audit Logs table ARN"
  type        = string
}

variable "dynamodb_app_audit_logs_table_name" {
  description = "Audit Logs DynamodDB table name"
  type        = string
}

variable "dynamodb_api_audit_logs_arn" {
  description = "API Audit Logs table ARN"
  type        = string
}

variable "dynamodb_api_audit_logs_table_name" {
  description = "API Audit Logs DynamodDB table name"
  type        = string
}

variable "sns_topic_alert_critical_arn" {
  description = "SNS topic ARN that critical alerts are sent to"
  type        = string
}

variable "ecs_iam_role_arn" {
  description = "ECS IAM role ARN"
  type        = string
}

variable "reliability_file_storage_arn" {
  description = "S3 bucket arn for reliability file storage"
  type        = string
}

variable "vault_file_storage_arn" {
  description = "S3 bucket arn for vault file storage"
  type        = string
}

variable "vault_file_storage_id" {
  description = "S3 bucket id for vault file storage"
  type        = string
}

variable "archive_storage_arn" {
  description = "S3 bucket arn for archive storage"
  type        = string
}

variable "archive_storage_id" {
  description = "S3 bucket id for archive storage"
  type        = string
}

variable "audit_logs_archive_storage_id" {
  description = "S3 bucket ID for audit logs archive storage"
  type        = string
}

variable "prisma_migration_storage_id" {
  description = "S3 bucket ID for prisma migration storage"
  type        = string
}

variable "prisma_migration_storage_arn" {
  description = "S3 bucket ARN for prisma migration storage"
  type        = string
}

variable "audit_logs_archive_storage_arn" {
  description = "S3 bucket ARN for audit logs archive storage"
  type        = string
}

variable "ecr_repository_lambda_urls" {
  description = "URLs of the Lambda ECRs"
  type        = map(string)
}

variable "lambda_security_group_id" {
  description = "Security group ID for the Lambdas"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "redis_port" {
  description = "Redis port used by the Nagware function"
  type        = number
}

variable "redis_url" {
  description = "Redis URL used by the Nagware function.  This should not include the protocol or port."
  type        = string
}