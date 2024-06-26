output "alb_security_group_id" {
  description = "Load balancer security group ID"
  value       = aws_security_group.forms_load_balancer.id
}

output "ecs_security_group_id" {
  description = "ECS task security group ID"
  value       = aws_security_group.forms.id
}

output "egress_security_group_id" {
  description = "Internet egress security group ID"
  value       = aws_security_group.forms_egress.id
}

output "idp_db_security_group_id" {
  description = "IdP database security group ID"
  value       = aws_security_group.idp_db.id
}

output "idp_ecs_security_group_id" {
  description = "IdP ECS task security group ID"
  value       = aws_security_group.idp_ecs.id
}

output "idp_lb_security_group_id" {
  description = "IdP load balancer security group ID"
  value       = aws_security_group.idp_lb.id
}

output "public_subnet_ids" {
  description = "List of the VPC's public subnet IDs"
  value       = aws_subnet.forms_public.*.id
}

output "private_subnet_ids" {
  description = "List of the VPC's private subnet IDs"
  value       = aws_subnet.forms_private.*.id
}

output "privatelink_security_group_id" {
  description = "Privatelink security group ID"
  value       = aws_security_group.privatelink.id
}

output "rds_security_group_id" {
  description = "RDS database task security group ID"
  value       = aws_security_group.forms_database.id
}

output "redis_security_group_id" {
  description = "Redis security group ID"
  value       = aws_security_group.forms_redis.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.forms.id
}

