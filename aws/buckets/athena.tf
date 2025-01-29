#
# Holds Athena query resuts
#
module "athena_bucket" {
  source            = "github.com/cds-snc/terraform-modules//S3?ref=17994187b8628dc5decf74ead84768501378df4c" # ref for v10.0.0
  bucket_name       = "cds-data-lake-athena-${var.env}"
  billing_tag_value = var.billing_tag_value

  logging = {
    target_bucket = module.log_bucket.s3_bucket_id
    target_prefix = "athena/"
  }

  lifecycle_rule = [
    local.lifecycle_expire_all,
    local.lifecycle_remove_noncurrent_versions
  ]

  versioning = {
    enabled = true
  }
}
