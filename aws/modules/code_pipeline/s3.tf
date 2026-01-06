resource "aws_s3_bucket" "codepipeline_bucket" {
  # checkov:skip=CKV_AWS_18: Access logging not required
  # checkov:skip=CKV_AWS_21: Versioning not required
  # checkov:skip=CKV2_AWS_62: Event notifications not required
  # checkov:skip=CKV2_AWS_61: Lifecycle configuration not required
  bucket        = "${local.account_id}-pipeline"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}



resource "aws_s3_bucket_ownership_controls" "codepipeline_bucket" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_bucket" {
  bucket = aws_s3_bucket.codepipeline_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

