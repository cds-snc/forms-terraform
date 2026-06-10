
module "guard_duty" {
  source = "github.com/cds-snc/terraform-modules//guardduty_malware_s3?ref=94729229cfcb754146c82a566227e55df6612228" # v11.3.5


  s3_bucket_name = var.reliability_storage_id
  tagging_status = "ENABLED"


  billing_tag_value = "GCForms-${var.env}"
}
