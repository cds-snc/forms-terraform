
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
  type        = string
}

variable "app_name" {
  description = "Application Name that will be built and deployed"
  type        = string
}

variable "github_repo_name" {
  description = "GitHub repo name for the app repository"
  type        = string
}

variable "webhook_secret" {
  description = "Secret for GitHub HMAC auth of webhook"
  type        = string
  sensitive   = true
}

variable "app_ecr_name" {
  description = "ECR repository name for the app"
  type        = string
}

variable "app_ecr_url" {
  description = "ECR repository url for the app"
  type        = string
}

variable "task_definition_family" {
  description = "Task Definiton family of the ECS service"
  type        = string
}

variable "app_container_name" {
  description = "Applications container name in the task definition"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS Cluster name of the app"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS Service name of the app"
  type        = string
}

variable "load_balancer_listener_arns" {
  description = "Load Balancer Listeners that direct traffic to the app"
  type        = list(string)
}

variable "loadblancer_target_group_names" {
  description = "List of target group names that direct traffic to the application"
  type        = list(string)
}

variable "docker_build_env_vars_plaintext" {
  description = "Environment value key / values required during the docker build - plain text"
  type = list(object({
    key   = string
    value = string
  }))
  default = []
}

variable "docker_build_env_vars_secrets" {
  description = "Environment value key / secret manager arns required during the docker build - secrets"
  type = list(object({
    key   = string
    value = string
  }))
  default = []
}

variable "docker_build_env_vars_parameter_store" {
  description = "Environment value key / parameter-store names required during the docker build - parameter store"
  type = list(object({
    key   = string
    value = string
  }))
  default = []
}