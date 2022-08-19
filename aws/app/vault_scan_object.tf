module "vault_scan_object" {
  source = "github.com/cds-snc/terraform-modules?ref=v3.0.13//S3_scan_object"

  product_name          = "vault"
  s3_upload_bucket_name = aws_s3_bucket.vault_file_storage.id

  alarm_on_lambda_error     = true
  alarm_error_sns_topic_arn = var.sns_topic_alert_warning_arn
  alarm_ok_sns_topic_arn    = var.sns_topic_alert_ok_arn

  billing_tag_value = var.billing_tag_value
}
