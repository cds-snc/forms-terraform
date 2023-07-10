module "vault_scan_object" {
  source = "github.com/cds-snc/terraform-modules?ref=v6.1.1//S3_scan_object"

  s3_upload_bucket_name = aws_s3_bucket.vault_file_storage.id
  billing_tag_value     = var.billing_tag_value
}
