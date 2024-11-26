module "etl_bucket" {
  source            = "github.com/cds-snc/terraform-modules//S3?ref=v10.0.0"
  bucket_name       = "cds-data-etl-bucket-${var.env}"
  billing_tag_value = var.billing_tag_value

  logging = {
    target_bucket = module.log_bucket.s3_bucket_id
    target_prefix = "dataetl/"
  }

  lifecycle_rule = [
    local.lifecycle_remove_noncurrent_versions,
    local.lifecycle_transition_storage
  ]

  versioning = {
    enabled = true
  }
}
