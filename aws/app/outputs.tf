output "ecs_cloudwatch_log_group_name" {
  description = "ECS task's CloudWatch log group name"
  value       = aws_cloudwatch_log_group.forms.name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.forms.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.form_viewer.name
}
