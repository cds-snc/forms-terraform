
module "guard_duty" {
  source = "github.com/cds-snc/terraform-modules//guardduty_malware_s3?ref=08f883bf79388eeef2afc01f4618c47ebb641fb4" # v10.5.1"


  s3_bucket_name = var.reliability_storage_id
  tagging_status = "ENABLED"


  billing_tag_value = "GCForms-${var.env}"
}