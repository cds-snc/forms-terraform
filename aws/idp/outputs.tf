output "ecs_idp_cluster_name" {
  description = "IdP's ECS cluster name"
  value       = module.idp_ecs.cluster_name
}

output "ecs_idp_cloudwatch_log_group_name" {
  description = "IdP's ECS CloudWatch log group name"
  value       = module.idp_ecs.cloudwatch_log_group_name
}

output "ecs_idp_service_name" {
  description = "IdP's ECS service name"
  value       = module.idp_ecs.service_name
}

output "ecs_idp_service_port" {
  description = "IdP's ECS service port"
  value       = module.idp_ecs.service_port
}

output "lb_idp_arn_suffix" {
  description = "IdP's load balancer ARN suffix"
  value       = aws_lb.idp.arn_suffix
}

output "lb_idp_target_groups_arn_suffix" {
  description = "IdP's load balancer target groups ARN suffixes"
  value = {
    for version in local.protocol_versions : version => aws_lb_target_group.idp[version].arn_suffix
  }
}

output "rds_idp_cluster_identifier" {
  description = "IdP's RDS cluster identifier"
  value       = module.idp_database.rds_cluster_id
}
