module "vault_scan_object" {
  source = "github.com/cds-snc/terraform-modules//S3_scan_object?ref=v6.1.3"

  s3_upload_bucket_name = var.vault_file_storage_id
  billing_tag_value     = var.billing_tag_value
}
