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

variable "s3_vault_file_storage_arn" {
  description = "ARN of the S3 bucket used for the Vault's file storage"
  type        = string
}

variable "security_group_id_api_ecs" {
  description = "ID of the security group for the API ECS service"
  type        = string
}
