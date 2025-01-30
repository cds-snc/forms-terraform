# The private subnets are required to match the cluster instance's availability zone
# to its subnet ID.
data "aws_subnet" "private" {
  for_each = toset(var.private_subnet_ids)
  id       = each.value
}

output "database_secret_arn" {
  description = "value"
  value       = aws_secretsmanager_secret_version.database_secret.arn
}

output "database_url_secret_arn" {
  description = "value"
  value       = aws_secretsmanager_secret_version.database_url.arn
}

output "rds_cluster_arn" {
  description = "RDS cluster ARN"
  value       = aws_rds_cluster.forms.arn
}

output "rds_cluster_identifier" {
  description = "RDS cluster identifier"
  value       = aws_rds_cluster.forms.cluster_identifier
}

output "rds_cluster_instance_availability_zone" {
  description = "RDS cluster instance's availability zone"
  value       = aws_rds_cluster_instance.forms.availability_zone
}

output "rds_cluster_instance_subnet_id" {
  description = "RDS cluster instance's subnet ID, null if not found"
  value = try(
    [for subnet in data.aws_subnet.private : subnet.id if subnet.availability_zone == aws_rds_cluster_instance.forms.availability_zone],
    null
  )
}

output "rds_connector_secret_name" {
  description = "RDS connector secret name"
  value       = aws_secretsmanager_secret.rds_connector.name
}

output "rds_db_name" {
  description = "Name of the database"
  value       = var.rds_db_name
}

output "rds_cluster_endpoint" {
  description = "RDS cluster endpoint"
  sensitive   = true
  value       = aws_rds_cluster.forms.endpoint
}