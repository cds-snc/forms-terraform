resource "aws_s3_bucket_replication_configuration" "forms_s3_replicate_to_platform_data_lake" {
  role   = aws_iam_role.forms_s3_replicate.arn
  bucket = var.datalake_bucket_name

  rule {
    id       = "send-to-platform-data-lake"
    status   = "Disabled" # Temporarily disabled until testing is complete
    priority = 10

    destination {
      bucket = local.platform_data_lake_raw_s3_bucket_arn
    }
  }
}
