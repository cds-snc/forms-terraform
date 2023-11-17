resource "aws_s3_bucket" "maintenance_mode" {
  # checkov:skip=CKV2_AWS_6: Public access block is define in a different resource
  # checkov:skip=CKV_AWS_18: Versioning not required
  # checkov:skip=CKV_AWS_19: False-positive, server side encryption is enabled but probably not detected because defined in a different Terraform resource
  # checkov:skip=CKV_AWS_21: Access logging not required
  bucket = "gc-forms-application-maintenance-page"

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_s3_bucket_acl" "maintenance_mode" {
  bucket = aws_s3_bucket.maintenance_mode.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "maintenance_mode" {
  bucket                  = aws_s3_bucket.maintenance_mode.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "allow_cloudfront_to_access_static_website_in_s3" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.maintenance_mode.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.maintenance_mode.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront_to_access_static_website_in_s3" {
  bucket = aws_s3_bucket.maintenance_mode.id
  policy = data.aws_iam_policy_document.allow_cloudfront_to_access_static_website_in_s3.json
}

resource "aws_s3_bucket_server_side_encryption_configuration" "maintenance_mode" {
  bucket = aws_s3_bucket.maintenance_mode.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_website_configuration" "maintenance_mode" {
  bucket = aws_s3_bucket.maintenance_mode.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_object" "maintenance_static_page" {
  bucket       = aws_s3_bucket.maintenance_mode.bucket
  key          = "index.html"
  source       = "./static_website/index.html"
  content_type = "text/html"
  etag         = filemd5("./static_website/index.html")
}