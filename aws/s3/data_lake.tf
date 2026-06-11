#
# Holds ETL scripts
#
module "etl_bucket" {
  source            = "github.com/cds-snc/terraform-modules//S3?ref=94729229cfcb754146c82a566227e55df6612228" # v11.3.5
  bucket_name       = "cds-forms-data-etl-bucket-${local.env}"
  billing_tag_value = var.billing_tag_value
  force_destroy     = var.env == "development"


  logging = {
    target_bucket = module.log_bucket.s3_bucket_id
    target_prefix = "dataetl/"
  }

  lifecycle_rule = [
    local.lifecycle_remove_noncurrent_versions
  ]

  versioning = {
    enabled = true
  }
}

#
# Holds exported data from ETL transformations
#
module "lake_bucket" {
  source            = "github.com/cds-snc/terraform-modules//S3?ref=94729229cfcb754146c82a566227e55df6612228" # v11.3.5
  bucket_name       = "cds-forms-data-lake-bucket-${local.env}"
  billing_tag_value = var.billing_tag_value
  force_destroy     = var.env == "development"

  logging = {
    target_bucket = module.log_bucket.s3_bucket_id
    target_prefix = "datalake/"
  }

  lifecycle_rule = [
    local.lifecycle_remove_noncurrent_versions,
    local.lifecycle_transition_storage
  ]

  versioning = {
    enabled = true
  }
}

#
# Bucket access logs, stored for 30 days
#
module "log_bucket" {
  source            = "github.com/cds-snc/terraform-modules//S3_log_bucket?ref=94729229cfcb754146c82a566227e55df6612228" # v11.3.5
  bucket_name       = "cds-forms-data-lake-bucket-logs-${local.env}"
  versioning_status = "Enabled"
  force_destroy     = var.env == "development"

  lifecycle_rule = [
    local.lifecycle_expire_all,
    local.lifecycle_remove_noncurrent_versions
  ]

  billing_tag_value = var.billing_tag_value
}
