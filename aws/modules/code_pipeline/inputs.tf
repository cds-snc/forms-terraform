variable "region" {
  description = "The current AWS region"
  type        = string
}

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

variable "build_env_vars_plaintext" {
  description = "Environment variable injected during build process - plain text"
  type = list(object({
    key   = string
    value = string
  }))
  default = []
}

variable "build_env_vars_from_secrets" {
  description = "Environment variable injected during build process - retrieved from AWS Secrets Manager"
  type = list(object({
    key       = string
    secretArn = string
  }))
  default = []
}

variable "build_env_vars_from_parameter_store" {
  description = "Environment variable injected during build process - retrieved from AWS Parameter Store"
  type = list(object({
    key           = string
    parameterName = string
    parameterArn  = string
  }))
  default = []
}

variable "docker_build_args" {
  description = "Arguments to be passed to the Docker build command. It can reference build environment variables using $<key>."
  type = list(object({
    key   = string
    value = string
  }))
  default = []
}

variable "custom_post_build_commands" {
  description = "Custom build commands to be executed after the Docker image has been built tagged and pushed to ECR"
  type        = list(string)
  default     = []
}

variable "github_trigger" {
  description = "Pipeline trigger configuration (excludeFilePaths is optional and can only be set when mode is DeployOnNewCommit)"

  type = object({
    mode             = string
    excludeFilePaths = optional(list(string))
  })

  validation {
    condition     = contains(["DeployOnNewCommit", "DeployOnNewTag"], var.github_trigger.mode)
    error_message = "Valid values for 'mode' are 'DeployOnNewCommit' or 'DeployOnNewTag'"
  }

  validation {
    condition     = (var.github_trigger.mode == "DeployOnNewCommit" || (var.github_trigger.mode == "DeployOnNewTag" && var.github_trigger.excludeFilePaths == null))
    error_message = "'excludeFilePaths' is not allowed when mode is set to 'DeployOnNewTag'"
  }
}

variable "build_compute_type" {
  type        = string
  description = "Defines the compute capacity allocated to the builder machine. This impacts CPU and memory available during builds. Valid values: 'small' or 'large'"

  default = "small"

  validation {
    condition     = contains(["small", "large"], var.build_compute_type)
    error_message = "Valid values for 'build_compute_type' are 'small' or 'large'"
  }
}
