variable "codedeploy_manual_deploy_enabled" {
  description = "Enable manual CodeDeploy deployments"
  type        = bool
}

variable "codedeploy_termination_wait_time_in_minutes" {
  description = "Number of minutes to waith for a CodeDeploy to terminate"
  type        = number
}

variable "database_url_secret_arn" {
  description = "Database URL secret version ARN, used by the ECS task"
  type        = string
}

variable "dynamodb_relability_queue_arn" {
  description = "Reliability queue DynamodDB table ARN"
  type        = string
}

variable "dynamodb_vault_arn" {
  description = "Vault DynamodDB table ARN"
  type        = string
}

variable "ecs_autoscale_enabled" {
  description = "Should memory/CPU threshold ECS task scaling be enabled"
  type        = bool
}

variable "ecs_form_viewer_name" {
  description = "Name of the ECS form viewer service"
  type        = string
}

variable "ecr_repository_url_form_viewer" {
  description = "ECR repository URL for the ECS task's Docker image"
  type        = string
}

variable "ecs_min_tasks" {
  description = "The minimum number of ECS tasks that should run in the cluster"
  type        = number
}

variable "ecs_max_tasks" {
  description = "The maximum number of ECS tasks that should run in the cluster"
  type        = number
}

variable "ecs_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_scale_cpu_threshold" {
  description = "Cluster CPU use threshold that causes an ECS task scaling event"
  type        = number
}

variable "ecs_scale_memory_threshold" {
  description = "Cluster memory use threshold that causes an ECS task scaling event"
  type        = number
}

variable "ecs_scale_in_cooldown" {
  description = "Amount of time, in seconds, before another scale-in event can occur"
  type        = number
}

variable "ecs_scale_out_cooldown" {
  description = "Amount of time, in seconds, before another scale-out event can occur"
  type        = number
}

variable "ecs_security_group_id" {
  description = "Forms ECS task security group ID"
  type        = string
}

variable "ecs_token_secret_arn" {
  description = "Forms ECS JSON Web Token (JWT) secret used by Templates lambda"
  type        = string
  sensitive   = true
}

variable "egress_security_group_id" {
  description = "Egress to the internet security group, used by the ECS task for authentication"
  type        = string
}

variable "recaptcha_secret_arn" {
  description = "Secret Site Key for reCAPTCHA arn"
  type        = string
  sensitive   = true
}

variable "recaptcha_public" {
  description = "reCAPTCHA public key, client side"
  type        = string
}

variable "notify_callback_bearer_token_secret_arn" {
  description = "GC Notify callback bearer token which will be used as an authentication factor in GC Forms"
  type        = string
  sensitive   = true
}

variable "kms_key_cloudwatch_arn" {
  description = "CloudWatch KMS key ARN, used by the ECS task's CloudWatch log group"
  type        = string
}

variable "kms_key_dynamodb_arn" {
  description = "DynamoDB KMS key ARN, used by the Lambdas"
  type        = string
}

variable "lb_https_listener_arn" {
  description = "Load balancer HTTPS listener ARN"
  type        = string
}

variable "lb_target_group_1_arn" {
  description = "Load balancer target group 1 ARN"
  type        = string
}

variable "lb_target_group_1_name" {
  description = "Load balancer target group 1 name, used by CodeDeploy to alternate blue/green deployments"
  type        = string
}

variable "lb_target_group_2_name" {
  description = "Load balancer target group 2 name, used by CodeDeploy to alternate blue/green deployments"
  type        = string
}

variable "metric_provider" {
  description = "Metric provider, used by the ECS task"
  type        = string
}

variable "notify_api_key_secret_arn" {
  description = "The Notify API key secret used by the ECS task and Lambda arn"
  type        = string
  sensitive   = true
}

variable "freshdesk_api_key_secret_arn" {
  description = "The FreshDesk API key secret used by the ECS task and Lambda"
  type        = string
  sensitive   = true
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the ECS service"
  type        = list(string)
}

variable "redis_url" {
  description = "Redis URL used by the ECS task"
  type        = string
}

variable "sqs_reprocess_submission_queue_arn" {
  description = "SQS reprocess submission queue ARN"
  type        = string
}

variable "sqs_reprocess_submission_queue_id" {
  description = "SQS reprocess submission queue URL"
  type        = string
}



variable "sqs_audit_log_queue_arn" {
  description = "SQS audit log queue ARN"
  type        = string
}

variable "sqs_audit_log_queue_id" {
  description = "SQS audit log queue URL"
  type        = string
}

variable "tracer_provider" {
  description = "Tracer provider, used by the ECS task"
  type        = string
}

variable "gc_template_id" {
  description = "GC Notify send a notification templateID"
  type        = string
}

variable "gc_temp_token_template_id" {
  description = "GC Notify temporary token templateID"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "User Pool ARN for the Forms Client"
  type        = string
}

variable "cognito_client_id" {
  description = "User Pool Client ID for Forms Client"
  type        = string
}

variable "cognito_endpoint_url" {
  description = "Cognito endpoint url"
  type        = string
}

variable "email_address_contact_us" {
  description = "Email address for Form Contact Us"
  type        = string
}

variable "email_address_support" {
  description = "Email address for Form Support"
  type        = string
}

variable "reliability_file_storage_id" {
  description = "id of the reliability file storage bucket"
  type        = string
}

variable "vault_file_storage_id" {
  description = "id of the vault file storage bucket"
  type        = string
}

variable "reliability_file_storage_arn" {
  description = "arn of the reliability file storage bucket"
  type        = string
}

variable "vault_file_storage_arn" {
  description = "arn of the vault file storage bucket"
  type        = string
}