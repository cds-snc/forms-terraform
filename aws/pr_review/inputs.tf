variable "vpc_id" {
  description = "VPC ID to attach the Lambda's security group to"
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

variable "forms_lambda_client_iam_role_name" {
  description = "IAM role name for forms client Lambda"
  type        = string
}

variable "idp_ecs_security_group_id" {
  description = "IdP ECS task security group ID"
  type        = string
}
