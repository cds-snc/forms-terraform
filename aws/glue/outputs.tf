output "glue_crawler_log_group_name" {
  description = "The name of the Glue Crawler CloudWatch log group."
  value       = local.glue_crawler_log_group_name
}

output glue_database_name {
  description = "The name of the Glue database."
  value       = aws_glue_catalog_database.rds_db_catalog.name
}