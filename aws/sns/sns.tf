#
# SNS topics
#
resource "aws_sns_topic" "alert_critical" {
  name              = "alert-critical"
  kms_master_key_id = var.kms_key_cloudwatch_arn

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_sns_topic" "alert_warning" {
  name              = "alert-warning"
  kms_master_key_id = var.kms_key_cloudwatch_arn

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_sns_topic" "alert_ok" {
  name              = "alert-ok"
  kms_master_key_id = var.kms_key_cloudwatch_arn
  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_sns_topic" "alert_warning_us_east" {
  provider = aws.us-east-1

  name              = "alert-warning"
  kms_master_key_id = var.kms_key_cloudwatch_us_east_arn
  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_sns_topic" "alert_ok_us_east" {
  provider = aws.us-east-1

  name              = "alert-ok"
  kms_master_key_id = var.kms_key_cloudwatch_us_east_arn
  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}