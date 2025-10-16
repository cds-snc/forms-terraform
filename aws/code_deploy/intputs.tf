
variable "private_subnet_ids" {
  description = "The list of private subnet IDs used by the RDS cluster to"
  type        = list(string)
}

variable "vpc_id" {
  description = "The VPC ID to create the resources in."
  type        = string
}

variable "code_build_security_group_id" {
  description = "Code Build Security Group"
  type = string
}

variable "database_url_secret_arn" {
  description = "Database URL secret version ARN, used by the ECS task"
  type        = string
}
