variable "vpc_id" {
  description = "VPC ID to attach the Lambda's security group to"
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

variable "privatelink_security_group_id" {
  description = "Security group ID for the private link"
  type        = string
}

variable "forms_database_security_group_id" {
  description = "Security group ID for the database"
  type        = string
}

variable "forms_redis_security_group_id" {
  description = "Security group ID for the redis"
  type        = string
}