module "vault_scan_object" {
  source = "github.com/cds-snc/terraform-modules//S3_scan_object?ref=bd904d01094f196fd3e8ff5c46e73838f1f1be26"

  s3_upload_bucket_name = var.vault_file_storage_id
  billing_tag_value     = var.billing_tag_value
}
