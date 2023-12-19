resource "aws_s3_bucket" "maintenance_mode" {
  # checkov:skip=CKV_AWS_18: Versioning not required
  # checkov:skip=CKV_AWS_21: Access logging not required
  bucket = "gc-forms-${var.env}-application-maintenance-page"

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_s3_bucket_ownership_controls" "maintenance_mode" {
  bucket = aws_s3_bucket.maintenance_mode.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "maintenance_mode" {
  depends_on = [aws_s3_bucket_ownership_controls.maintenance_mode]
  bucket     = aws_s3_bucket.maintenance_mode.id
  acl        = "private"
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

resource "aws_s3_object" "maintenance_static_page_html_files" {
  for_each     = fileset("./static_website/", "*.html")
  content_type = "text/html"
  bucket       = aws_s3_bucket.maintenance_mode.id
  key          = each.value
  source       = "./static_website/${each.value}"
  etag         = filemd5("./static_website/${each.value}")
}

resource "aws_s3_object" "maintenance_static_page_css_files" {
  for_each     = fileset("./static_website/", "*.css")
  content_type = "text/css"
  bucket       = aws_s3_bucket.maintenance_mode.id
  key          = each.value
  source       = "./static_website/${each.value}"
  etag         = filemd5("./static_website/${each.value}")
}

resource "aws_s3_object" "maintenance_static_page_svg_files" {
  for_each     = fileset("./static_website/", "*.svg")
  content_type = "image/svg+xml"
  bucket       = aws_s3_bucket.maintenance_mode.id
  key          = each.value
  source       = "./static_website/${each.value}"
  etag         = filemd5("./static_website/${each.value}")
}

resource "aws_s3_object" "maintenance_static_page_ico_files" {
  for_each     = fileset("./static_website/", "*.ico")
  content_type = "image/png"
  bucket       = aws_s3_bucket.maintenance_mode.id
  key          = each.value
  source       = "./static_website/${each.value}"
  etag         = filemd5("./static_website/${each.value}")
}