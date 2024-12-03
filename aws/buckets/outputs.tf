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

output "athena_bucket_arn" {
  description = "ARN of the S3 Athena query result bucket."
  value       = module.athena_bucket.s3_bucket_arn
}

output "athena_bucket_name" {
  description = "Name of the S3 Athena query result bucket."
  value       = module.athena_bucket.s3_bucket_id
}
