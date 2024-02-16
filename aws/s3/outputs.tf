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

output "lambda_code_id" {
  description = "S3 bucket id for lambda code"
  value       = aws_s3_bucket.lambda_code.id
}

output "lambda_code_arn" {
  description = "S3 bucket arn for lambda code"
  value       = aws_s3_bucket.lambda_code.arn
}

output "audit_logs_archive_storage_id" {
  description = "S3 bucket ID for audit logs archive storage"
  value       = aws_s3_bucket.audit_logs_archive_storage.id
}

output "audit_logs_archive_storage_arn" {
  description = "S3 bucket ARN for audit logs archive storage"
  value       = aws_s3_bucket.audit_logs_archive_storage.arn
}