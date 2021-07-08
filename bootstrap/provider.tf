provider "aws" {
  region = "ca-central-1"
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = join("", [var.storage_bucket, "-logs"])
  acl    = "log-delivery-write"
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

resource "aws_s3_bucket_public_access_block" "log_bucket" {
	bucket = aws_s3_bucket.log_bucket.id
	block_public_acls   = true
	block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "storage_bucket" {
  bucket = var.storage_bucket
  acl    = "private"
  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "log/"
  }
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "storage_bucket" {
	bucket = aws_s3_bucket.storage_bucket.id
	block_public_acls   = true
	block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-lock"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  #tfsec:ignore:AWS086
  # Ignore using global encryption key
  #tfsec:ignore:AWS092

  tags = {
    ("CostCentre") = "Forms"
  }
}
