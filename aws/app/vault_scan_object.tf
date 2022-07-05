module "vault_scan_object" {
  source = "github.com/cds-snc/terraform-modules?ref=v3.0.7//S3_scan_object"

  product_name            = "vault"
  s3_upload_bucket_name   = aws_s3_bucket.vault_file_storage.id
  s3_upload_bucket_create = false

  billing_tag_value = var.billing_tag_value
}
