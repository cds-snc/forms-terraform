#
# Bucket access logs, stored for 30 days
#
module "log_bucket" {
  source            = "github.com/cds-snc/terraform-modules//S3_log_bucket?ref=17994187b8628dc5decf74ead84768501378df4c" # ref for v10.0.0
  bucket_name       = "cds-data-lake-bucket-logs-${var.env}"
  versioning_status = "Enabled"

  lifecycle_rule = [
    local.lifecycle_expire_all,
    local.lifecycle_remove_noncurrent_versions
  ]

  billing_tag_value = var.billing_tag_value
}