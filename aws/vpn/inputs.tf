variable "vpc_cidr_block" {
  description = "IP CIDR block of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "The list of private subnet IDs to attach the RDS cluster to"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "The security group used by ECS"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}