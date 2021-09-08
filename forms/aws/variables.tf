###
# Global
###
variable "region" {
  type = string
}

variable "billing_tag_key" {
  type = string
}

variable "billing_tag_value" {
  type = string
}

variable "environment" {
  type = string
}
###
# Global Secret
###

variable "slack_webhook" {
  type = string
}

###
# AWS Cloud Watch - cloudwatch.tf
###
variable "cloudwatch_log_group_name" {
  type = string
}

###
# AWS ECS - ecs.tf
###

variable "list_manager_host" {
  type = string
}

variable "ircc_config" {
  type= string
}

variable "github_sha" {
  type    = string
  default = ""
}

variable "ecs_name" {
  type = string
}

variable "scale_in_cooldown" {
  type    = number
  default = 60
}
variable "scale_out_cooldown" {
  type    = number
  default = 60
}
variable "cpu_scale_metric" {
  type    = number
  default = 60
}
variable "memory_scale_metric" {
  type    = number
  default = 60
}
variable "min_capacity" {
  type    = number
  default = 1
}
variable "max_capacity" {
  type    = number
  default = 2
}

# Task Forms
variable "ecs_form_viewer_name" {
  type = string
}

# Task Forms Secrets

variable "ecs_secret_notify_api_key" {
  type = string
}
variable "ecs_secret_google_client_id" {
  type = string
}
variable "ecs_secret_google_client_secret" {
  type = string
}

variable "ecs_list_management_api_key" {
  type = string
}


# Forms Scaling

variable "form_viewer_autoscale_enabled" {
  type = bool
}

variable "manual_deploy_enabled" {
  type    = bool
  default = false
}

variable "termination_wait_time_in_minutes" {
  type        = number
  description = "minutes to wait to terminate old deploy"
  default     = 1
}

# Metric provider
variable "metric_provider" {
  type = string
}

# Tracing provider
variable "tracer_provider" {
  type = string
}

###
# AWS VPC - networking.tf
###
variable "vpc_cidr_block" {
  type = string
}

variable "vpc_name" {
  type = string
}

###
# AWS RDS - rds.tf
###
# RDS Subnet Group
variable "rds_db_subnet_group_name" {
  type = string
}

# RDS DB - Key Retrieval/Submission
variable "rds_db_name" {
  type = string
}

variable "rds_name" {
  type = string
}

variable "rds_db_user" {
  type = string
}

variable "rds_db_password" {
  type = string
}

variable "rds_allocated_storage" {
  type = string
}

variable "rds_instance_class" {
  type = string
}

###
# AWS Route53 - route53.tf
###
variable "route53_zone_name" {
  type = string
}

