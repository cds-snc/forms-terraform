#
# Reliability Queue File Storage
#

resource "aws_s3_bucket" "reliability_file_storage" {
  # checkov:skip=CKV_AWS_18: Access logging not required
  # checkov:skip=CKV_AWS_21: Versioning not required
  # checkov:skip=CKV2_AWS_62: Event notifications not required
  bucket = "forms-${var.env}-reliability-file-storage"
}

resource "aws_s3_bucket_ownership_controls" "reliability_file_storage" {
  bucket = aws_s3_bucket.reliability_file_storage.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "reliability_file_storage" {
  # checkov:skip=CKV_AWS_300: Lifecycle configuration for aborting failed (multipart) upload not required
  bucket = aws_s3_bucket.reliability_file_storage.id

  rule {
    id     = "Clear Reliability Queue after 30 days"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reliability_file_storage" {
  bucket = aws_s3_bucket.reliability_file_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
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

#
# Vault File Storage
#

resource "aws_s3_bucket" "vault_file_storage" {
  # checkov:skip=CKV_AWS_18: Access logging not required
  # checkov:skip=CKV_AWS_21: Versioning not required
  # checkov:skip=CKV2_AWS_61: Lifecycle configuration not required
  # checkov:skip=CKV2_AWS_62: Event notifications not required
  bucket = "forms-${var.env}-vault-file-storage"
}

resource "aws_s3_bucket_ownership_controls" "vault_file_storage" {
  bucket = aws_s3_bucket.vault_file_storage.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vault_file_storage" {
  bucket = aws_s3_bucket.vault_file_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
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

#
# Archive Storage
#

resource "aws_s3_bucket" "archive_storage" {
  # checkov:skip=CKV_AWS_18: Access logging not required
  # checkov:skip=CKV_AWS_21: Versioning not required
  # checkov:skip=CKV2_AWS_62: Event notifications not required
  bucket = "forms-${var.env}-archive-storage"
}

resource "aws_s3_bucket_ownership_controls" "archive_storage" {
  bucket = aws_s3_bucket.archive_storage.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "archive_storage" {
  bucket = aws_s3_bucket.archive_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "archive_storage" {
  # checkov:skip=CKV_AWS_300: Lifecycle configuration for aborting failed (multipart) upload not required
  bucket = aws_s3_bucket.archive_storage.id

  rule {
    id     = "Clear Archive Storage after 30 days"
    status = "Enabled"

    expiration {
      days = 30
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

resource "aws_s3_bucket" "lambda_code" {
  # checkov:skip=CKV_AWS_18: Access logging not required
  # checkov:skip=CKV_AWS_21: Versioning not required
  # checkov:skip=CKV2_AWS_61: Lifecycle configuration not required
  # checkov:skip=CKV2_AWS_62: Event notifications not required
  bucket = "forms-${var.env}-lambda-code"
}

resource "aws_s3_bucket_ownership_controls" "lambda_code" {
  bucket = aws_s3_bucket.lambda_code.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "lambda_code" {
  bucket = aws_s3_bucket.lambda_code.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lambda_code" {
  bucket = aws_s3_bucket.lambda_code.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "lambda_code" {
  bucket                  = aws_s3_bucket.lambda_code.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#
# Audit Logs archive storage
#

resource "aws_s3_bucket" "audit_logs_archive_storage" {
  # checkov:skip=CKV_AWS_18: Access logging not required
  # checkov:skip=CKV_AWS_21: Versioning not required
  # checkov:skip=CKV2_AWS_62: Event notifications not required
  bucket = "forms-${var.env}-audit-logs-archive-storage"
}

resource "aws_s3_bucket_ownership_controls" "audit_logs_archive_storage" {
  bucket = aws_s3_bucket.audit_logs_archive_storage.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs_archive_storage" {
  bucket = aws_s3_bucket.audit_logs_archive_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "audit_logs_archive_storage" {
  bucket                  = aws_s3_bucket.audit_logs_archive_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "audit_logs_archive_storage" {
  # checkov:skip=CKV_AWS_300: Lifecycle configuration for aborting failed (multipart) upload not required
  bucket = aws_s3_bucket.audit_logs_archive_storage.id

  rule {
    id     = "Clear Audit Logs Archive Storage after 1 year and 11 months"
    status = "Enabled"

    expiration {
      days = 700
    }
  }
}