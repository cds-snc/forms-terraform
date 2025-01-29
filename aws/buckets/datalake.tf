#
# Holds exported data from ETL transformations
#

module "lake_bucket" {
  source            = "github.com/cds-snc/terraform-modules//S3?ref=17994187b8628dc5decf74ead84768501378df4c" # ref for v10.0.0
  bucket_name       = "cds-forms-data-lake-bucket-${var.env}"
  billing_tag_value = var.billing_tag_value

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

resource "aws_s3_bucket_policy" "lake_bucket" {
  bucket = module.lake_bucket.s3_bucket_id
}