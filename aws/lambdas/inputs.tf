
variable "notify_api_key_secret_arn" {
  description = "ARN of notify_api_key secret"
  type        = string
}

variable "gc_template_id" {
  description = "GC Notify send a notification templateID"
  type        = string
}

variable "token_secret_arn" {
  description = "Token secret used for app"
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

variable "sns_topic_alert_critical_arn" {
  description = "SNS topic ARN that critical alerts are sent to"
  type        = string
}


variable "ecs_iam_role_arn" {
  description = "ECS IAM role ARN"
  type        = string
}

variable "localstack_hosted" {
  description = "Whether or not the stack is hosted in localstack"
  type        = bool
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
  description = "S3 bucket idfor vault file storage"
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

variable "lambda_code_id" {
  description = "S3 bucket id for lambda code"
  type        = string
}

variable "lambda_code_arn" {
  description = "S3 bucket arn for lambda code"
  type        = string
}
