locals {
  scan_files_account = var.env == "production" ? "806545929748" : "127893201980"
}

module "vault_scan_object" {
  source = "github.com/cds-snc/terraform-modules//S3_scan_object?ref=1e2debaf58fdb65da1910f0d42efcc786ddd0722" // commit id for version 9.2.3

  s3_upload_bucket_names  = [var.vault_file_storage_id]
  s3_scan_object_role_arn = "arn:aws:iam::${local.scan_files_account}:role/s3-scan-object"
  scan_files_role_arn     = "arn:aws:iam::${local.scan_files_account}:role/scan-files-api"

  billing_tag_value = var.billing_tag_value
}
