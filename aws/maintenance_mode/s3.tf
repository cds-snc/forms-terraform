resource "aws_s3_bucket" "maintenance_mode" {
  # checkov:skip=CKV_AWS_18: Versioning not required
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

resource "aws_s3_bucket_server_side_encryption_configuration" "maintenance_mode" {
  bucket = aws_s3_bucket.maintenance_mode.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "maintenance_mode" {
  bucket                  = aws_s3_bucket.maintenance_mode.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "maintenance_mode" {
  bucket = aws_s3_bucket.maintenance_mode.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "maintenance_static_page" {
  bucket = aws_s3_bucket.maintenance_mode.bucket

  key          = "index.html"
  source       = "./static_website/index.html"
  content_type = "text/html"

  etag = filemd5("./static_website/index.html")
}