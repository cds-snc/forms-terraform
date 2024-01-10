locals {
  scan_files_account = var.env == "production" ? "806545929748" : "127893201980"
}

module "vault_scan_object" {
  source = "github.com/cds-snc/terraform-modules//S3_scan_object?ref=v9.0.0"

  s3_upload_bucket_name   = var.vault_file_storage_id
  s3_scan_object_role_arn = "arn:aws:iam::${local.scan_files_account}:role/s3-scan-object"
  scan_files_role_arn     = "arn:aws:iam::${local.scan_files_account}:role/scan-files-api"

  billing_tag_value = var.billing_tag_value
}
