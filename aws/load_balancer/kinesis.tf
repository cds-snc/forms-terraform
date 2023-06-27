#
# Kinesis Firehose
#
resource "aws_kinesis_firehose_delivery_stream" "firehose_waf_logs" {
  name        = "aws-waf-logs-forms"
  destination = "extended_s3"

  server_side_encryption {
    enabled = true
  }

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose_waf_logs.arn
    prefix             = "waf_acl_logs/AWSLogs/${var.account_id}/"
    bucket_arn         = local.cbs_satellite_bucket_arn
    compression_format = "GZIP"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

#
# Log bucket
# This is no longer being used and can be removed in 90 days from the 
# terraform apply date (expiration lifecycle_rule will have deleted all objects by then).
#
resource "aws_s3_bucket" "firehose_waf_logs" {
  # checkov:skip=CKV_AWS_18: Versioning not required
  # checkov:skip=CKV_AWS_21: Access logging not required  
  bucket = var.env == "production" ? "forms-waf-logs" : "forms-${var.env}-terraform-waf-logs"

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_rules" {
  bucket = aws_s3_bucket.firehose_waf_logs.id

  rule {
    id = "lifecycle_firehose_waf_logs"
    expiration {
      days = 90
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "firehose_waf_logs" {
  bucket = aws_s3_bucket.firehose_waf_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


resource "aws_s3_bucket_public_access_block" "firehose_waf_logs" {
  bucket                  = aws_s3_bucket.firehose_waf_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.firehose_waf_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "firehose_waf_logs" {
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]

  bucket = aws_s3_bucket.firehose_waf_logs.id
  acl    = "private"
}

#
# IAM role
#
resource "aws_iam_role" "firehose_waf_logs" {
  name               = "firehose_waf_logs"
  assume_role_policy = data.aws_iam_policy_document.firehose_waf_assume.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_iam_role_policy" "firehose_waf_logs" {
  name   = "firehose-waf-logs-policy"
  role   = aws_iam_role.firehose_waf_logs.id
  policy = data.aws_iam_policy_document.firehose_waf_policy.json
}

data "aws_iam_policy_document" "firehose_waf_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "firehose_waf_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      local.cbs_satellite_bucket_arn,
      "${local.cbs_satellite_bucket_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole"
    ]
    resources = [
      "arn:aws:iam::*:role/aws-service-role/wafv2.amazonaws.com/AWSServiceRoleForWAFV2Logging"
    ]
  }
}
