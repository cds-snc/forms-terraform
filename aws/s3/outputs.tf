output "reliability_file_storage_id" {
  description = "S3 bucket ID for reliability file storage"
  value       = aws_s3_bucket.reliability_file_storage.id
}

output "reliability_file_storage_arn" {
  description = "S3 bucket arn for reliability file storage"
  value       = aws_s3_bucket.reliability_file_storage.arn
}

output "vault_file_storage_id" {
  description = "S3 bucket ID for vault file storage"
  value       = aws_s3_bucket.vault_file_storage.id
}

output "vault_file_storage_arn" {
  description = "S3 bucket arn for vault file storage"
  value       = aws_s3_bucket.vault_file_storage.arn
}

output "archive_storage_id" {
  description = "S3 bucket ID for archive storage"
  value       = aws_s3_bucket.archive_storage.id
}

output "archive_storage_arn" {
  description = "S3 bucket arn for archive storage"
  value       = aws_s3_bucket.archive_storage.arn
}

output "audit_logs_archive_storage_id" {
  description = "S3 bucket ID for audit logs archive storage"
  value       = aws_s3_bucket.audit_logs_archive_storage.id
}

output "audit_logs_archive_storage_arn" {
  description = "S3 bucket ARN for audit logs archive storage"
  value       = aws_s3_bucket.audit_logs_archive_storage.arn
}

output "deployment_script_storage_id" {
  description = "S3 bucket ID for deployment script storage"
  value       = aws_s3_bucket.deployment_script_storage.id
}

output "deployment_script_storage_arn" {
  description = "S3 bucket ARN for deployment script storage"
  value       = aws_s3_bucket.deployment_script_storage.arn
}

output "lake_bucket_arn" {
  description = "ARN of the S3 Raw data bucket."
  value       = module.lake_bucket.s3_bucket_arn
}

output "lake_bucket_name" {
  description = "Name of the S3 Raw data bucket."
  value       = module.lake_bucket.s3_bucket_id
}

output "etl_bucket_arn" {
  description = "ARN of the S3 ETL bucket."
  value       = module.etl_bucket.s3_bucket_arn
}

output "etl_bucket_name" {
  description = "Name of the S3 ETL bucket."
  value       = module.etl_bucket.s3_bucket_id
}
