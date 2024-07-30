output "ecs_api_cluster_name" {
  description = "API's ECS cluster name"
  value       = module.api_ecs.cluster_name
}

output "ecs_api_cloudwatch_log_group_name" {
  description = "API's ECS CloudWatch log group name"
  value       = module.api_ecs.cloudwatch_log_group_name
}

output "ecs_api_service_name" {
  description = "API's ECS service name"
  value       = module.api_ecs.service_name
}
