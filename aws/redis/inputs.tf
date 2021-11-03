variable "private_subnet_ids" {
  description = "The list of private subnet IDs to attach Redis to"
  type        = list(string)
}

variable "redis_security_group_id" {
  description = "The security group used by Redis"
  type        = string
}
