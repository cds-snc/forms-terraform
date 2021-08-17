###
# AWS S3 bucket - WAF log target
###  
#tfsec:ignore:AWS002 tfsec:ignore:AWS077
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
}

resource "aws_s3_bucket_public_access_block" "firehose_waf_logs" {
  bucket                  = aws_s3_bucket.firehose_waf_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


###
# AWS S3 bucket - Reliability Queue File Storage
###
#tfsec:ignore:AWS002 tfsec:ignore:AWS077
resource "aws_s3_bucket" "reliability_file_storage" {
  bucket = "forms-staging-reliability_file_storage"
  acl    = "private"

  lifecycle_rule {
    enabled = true

    expiration {
      days = 5
    }
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "reliability_file_storage" {
  bucket                  = aws_s3_bucket.reliability_file_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

###
# AWS S3 bucket - Vault File Storage
###
#tfsec:ignore:AWS002 tfsec:ignore:AWS077
resource "aws_s3_bucket" "vault_file_storage" {
  bucket = "forms-staging-vault_file_storage"
  acl    = "private"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "vault_file_storage" {
  bucket                  = aws_s3_bucket.vault_file_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

###
# AWS S3 bucket - Archive Storage
###
#tfsec:ignore:AWS002 tfsec:ignore:AWS077
resource "aws_s3_bucket" "archive_storage" {
  bucket = "forms-staging-archive_storage"
  acl    = "private"

  lifecycle_rule {
    enabled = true
    expiration {
      days = 30
    }
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "archive_storage" {
  bucket                  = aws_s3_bucket.archive_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}