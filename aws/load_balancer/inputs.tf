variable "alb_security_group_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "hosted_zone_ids" {
  description = "Route53 hosted zone ID"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID to associate the load balancer with"
  type        = string
}

variable "gc_forms_application_health_check_id" {
  description = "GC Forms application health check identifier"
  type        = string
}

variable "maintenance_mode_cloudfront_distribution_domain_name" {
  description = "Domain name of Cloudfront distribution for maintenance mode"
  type        = string
}

variable "maintenance_mode_cloudfront_distribution_hosted_zone_id" {
  description = "Hosted zone identifier of Cloudfront distribution for maintenance mode"
  type        = string
}