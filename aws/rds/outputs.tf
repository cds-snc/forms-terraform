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

output "rds_db_name" {
  description = "Name of the database"
  value       = var.rds_db_name
}

output "rds_cluster_endpoint" {
  description = "RDS cluster endpoint"
  value       = aws_rds_cluster.forms.endpoint
}