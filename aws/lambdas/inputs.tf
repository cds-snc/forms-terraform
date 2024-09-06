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

variable "dynamodb_audit_logs_arn" {
  description = "Audit Logs table ARN"
  type        = string
}

variable "dynamodb_audit_logs_table_name" {
  description = "Audit Logs DynamodDB table name"
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

variable "localstack_hosted" {
  description = "Whether or not the stack is hosted in localstack"
  type        = bool
}

variable "audit_logs_archive_storage_id" {
  description = "S3 bucket ID for audit logs archive storage"
  type        = string
}

variable "audit_logs_archive_storage_arn" {
  description = "S3 bucket ARN for audit logs archive storage"
  type        = string
}

variable "ecr_repository_url_audit_logs_lambda" {
  description = "URL of the Audit Logs Lambda ECR"
  type        = string
}

variable "ecr_repository_url_audit_logs_archiver_lambda" {
  description = "URL of the Audit Logs Archiver Lambda ECR"
  type        = string
}

variable "ecr_repository_url_form_archiver_lambda" {
  description = "URL of the Form Archiver Lambda ECR"
  type        = string
}

variable "ecr_repository_url_nagware_lambda" {
  description = "URL of the Nagware Lambda ECR"
  type        = string
}

variable "ecr_repository_url_reliability_lambda" {
  description = "URL of the Reliability Lambda ECR"
  type        = string
}

variable "ecr_repository_url_reliability_dlq_consumer_lambda" {
  description = "URL of the Reliability DLQ Consumer Lambda ECR"
  type        = string
}

variable "ecr_repository_url_response_archiver_lambda" {
  description = "URL of the Response Archiver Lambda ECR"
  type        = string
}

variable "ecr_repository_url_submission_lambda" {
  description = "URL of the Submission Lambda ECR"
  type        = string
}

variable "ecr_repository_url_vault_integrity_lambda" {
  description = "URL of the Vault Integrity Lambda ECR"
  type        = string
}

variable "lambda_nagware_security_group_id" {
  description = "Security group ID for the Nagware Lambda"
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
