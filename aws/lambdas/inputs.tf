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

variable "sqs_reliability_reprocessing_queue_arn" {
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

variable "dynamodb_reliability_queue_arn" {
  description = "Reliability queue DynamodDB table ARN"
  type        = string
}

variable "dynamodb_reliability_stream_arn" {
  description = "Reliability DynamodDB stream ARN"
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

variable "reliability_file_storage_id" {
  description = "S3 bucket id for reliability file storage"
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

variable "ecs_iam_forms_secrets_manager_policy_arn" {
  description = "IAM policy for access to Secrets Manager"
  type        = string
}

variable "ecs_iam_forms_kms_policy_arn" {
  description = "IAM policy for access to KMS"
  type        = string
}

variable "ecs_iam_forms_s3_policy_arn" {
  description = "IAM policy access to S3"
  type        = string
}

variable "ecs_iam_forms_dynamodb_policy_arn" {
  description = "IAM policy for access to DynamoDB"
  type        = string
}

variable "ecs_iam_forms_sqs_policy_arn" {
  description = "IAM policy for access to SQS"
  type        = string
}

variable "ecs_iam_forms_cognito_policy_arn" {
  description = "IAM policy for access to Cognito"
  type        = string
}

// API end to end test

variable "idp_project_identifier" {
  description = "Project identifier of the identity provider"
  type        = string
}

variable "api_end_to_end_test_form_identifier" {
  description = "Identifier of the form used for the API end to end test"
  type        = string
}

variable "api_end_to_end_test_form_api_private_key" {
  description = "Private key of the form used for the API end to end test"
  type        = string
  sensitive   = true
}

variable "service_discovery_private_dns_namespace_ecs_local_name" {
  description = "Local ECS service discovery private DNS namespace name"
  type        = string
}

variable "ecs_idp_service_name" {
  description = "IdP's ECS service name"
  type        = string
}

variable "ecs_idp_service_port" {
  description = "IdP's ECS service port"
  type        = number
}

variable "ecs_api_service_name" {
  description = "API's ECS service name"
  type        = string
}

variable "ecs_api_service_port" {
  description = "API's ECS service port"
  type        = number
}

variable "api_end_to_end_test_lambda_security_group_id" {
  description = "API end to end test Lambda security group ID"
  type        = string
}
