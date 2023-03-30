variable "alb_security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID to associate the load balancer with"
  type        = string
}