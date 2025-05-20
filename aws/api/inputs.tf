variable "api_image_ecr_url" {
  description = "URL of the ECR repository for the API image"
  type        = string
}

variable "api_image_tag" {
  description = "Tag of the API image in the ECR repository"
  type        = string
}

variable "dynamodb_vault_arn" {
  description = "ARN of the DynamoDB Vault table"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ARN of the ECS cluster for the API"
  type        = string
}

variable "kms_key_dynamodb_arn" {
  description = "ARN of the KMS key used for encrypting the DynamoDB Vault table"
  type        = string
}

variable "lb_target_group_arn_api_ecs" {
  description = "ARN of the load balancer target group for the API ECS service"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets for the ECS service"
  type        = list(string)
}

variable "redis_port" {
  description = "Redis port used by the ECS task"
  type        = number
}

variable "redis_url" {
  description = "Redis URL used by the ECS task.  This should not include the protocol or port."
  type        = string
}

variable "s3_vault_file_storage_arn" {
  description = "ARN of the S3 bucket used for the Vault's file storage"
  type        = string
}

variable "security_group_id_api_ecs" {
  description = "ID of the security group for the API ECS service"
  type        = string
}

variable "zitadel_provider" {
  description = "The Zitadel provider endpoint used by the ECS task"
  type        = string
}

variable "zitadel_application_key_secret_arn" {
  description = "The Zitadel application key secret used by the ECS task"
  type        = string
  sensitive   = true
}

variable "freshdesk_api_key_secret_arn" {
  description = "The Freshdesk application key secret used by the ECS task"
  type        = string
  sensitive   = true
}

variable "rds_connection_url_secret_arn" {
  description = "The RDS connection URL secret used by the ECS task"
  type        = string
  sensitive   = true
}
variable "sqs_api_audit_log_queue_arn" {
  description = "SQS audit log queue ARN"
  type        = string
}

variable "service_discovery_private_dns_namespace_ecs_local_id" {
  description = "Local ECS service discovery private DNS namespace ID"
  type        = string
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
