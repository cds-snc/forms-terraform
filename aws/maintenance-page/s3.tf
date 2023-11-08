resource "aws_s3_bucket" "maintenance_page" {
  bucket = "gc-forms-application-maintenance-page"

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_s3_bucket_public_access_block" "maintenance_page" {
  bucket                  = aws_s3_bucket.maintenance_page.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "maintenance_page" {
  bucket = aws_s3_bucket.maintenance_page.id
  acl    = "private"
}

resource "aws_s3_bucket_website_configuration" "maintenance_page" {
  bucket = aws_s3_bucket.maintenance_page.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "maintenance_page" {
  bucket = aws_s3_bucket.maintenance_page.bucket
  key    = "index.html"
  source = "static-website/index.html"
  etag   = filemd5("static-website/index.html")

  depends_on = [ 
    aws_s3_bucket.aws_s3_bucket.maintenance_page
  ]
}