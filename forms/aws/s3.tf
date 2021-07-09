###
# AWS S3 bucket - WAF log target
###
resource "aws_s3_bucket" "firehose_waf_logs" {
  bucket = "forms-staging-terraform-waf-logs"
  acl    = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  #tfsec:ignore:AWS002
  #tfsec:ignore:AWS077

}

resource "aws_s3_bucket_public_access_block" "firehose_waf_logs" {
  bucket                  = aws_s3_bucket.firehose_waf_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
