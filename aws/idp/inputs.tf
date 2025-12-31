variable "hosted_zone_ids" {
  description = "The hosted zone IDs in the environments. The first one will be used for the IdP."
  type        = list(string)
}

variable "idp_database_cluster_admin_username" {
  description = "The IdP database cluster administrator's username. Note that this will craete a super user with access to all databases within the cluster."
  type        = string
  sensitive   = true
}

variable "idp_database_cluster_admin_password" {
  description = "The IdP database cluster admin's password. Note that this will create a super user with access to all databases within the cluster."
  type        = string
  sensitive   = true
}

variable "idp_database_min_acu" {
  description = "The minimum serverless capacity for the IdP RDS cluster. Each ACU is roughly equivalent to 2GB of memory and between 1-2 vCPU."
  type        = number
}

variable "idp_database_max_acu" {
  description = "The maximum serverless capacity for the IdP RDS cluster. Each ACU is roughly equivalent to 2GB of memory and between 1-2 vCPU."
  type        = number
}

variable "kinesis_firehose_waf_logs_arn" {
  description = "The Kinesis Firehose delivery stream ARN used to collect and write WAF ACL logs to an S3 bucket."
  type        = string
}

variable "private_subnet_ids" {
  description = "The private subnet IDs to create the resources in."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "The public subnet IDs to create the resources in."
  type        = list(string)
}

variable "security_group_idp_db_id" {
  description = "The security group ID of the IdP's database cluster."
  type        = string
}

variable "security_group_idp_ecs_id" {
  description = "The security group ID of the IdP's ECS cluster."
  type        = string
}

variable "security_group_idp_lb_id" {
  description = "The security group ID of the IdP's load balancer."
  type        = string
}

variable "waf_ipv4_blocklist_arn" {
  description = "The WAF ACL IPv4 blocklist ARN."
  type        = string
}

variable "zitadel_admin_password" {
  description = "Zitadel administrator password."
  type        = string
  sensitive   = true
}

variable "zitadel_admin_username" {
  description = "Zitadel administrator username."
  type        = string
  sensitive   = true
}

variable "zitadel_database_name" {
  description = "The name of the Zitadel database within the IdP RDS cluster."
  type        = string
  sensitive   = true
}

variable "zitadel_image_ecr_url" {
  description = "The Zitadel Docker image ECR repository URL."
  type        = string
}

variable "zitadel_image_tag" {
  description = "The Zitadel Docker image tag to deploy in the ECS cluster."
  type        = string
}

variable "zitadel_secret_key" {
  description = "The secret key to use for Zitadel."
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "The VPC ID to create the resources in."
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

#####################
## IDP Hosted Login
#####################


variable "idp_login_ecr_url" {
  description = "The Hosted Login Docker image ECR repository URL."
  type        = string
}

variable "idp_login_service_user_token" {
  description = "The service user token that allows communication with the Zitadel API"
  type        = string
  sensitive   = true
}

variable "kms_key_cloudwatch_arn" {
  description = "CloudWatch KMS key ARN, used by the ECS task's CloudWatch log group"
  type        = string
}