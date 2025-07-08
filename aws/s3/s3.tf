#
# Reliability Queue File Storage
#

resource "aws_s3_bucket" "reliability_file_storage" {
  # checkov:skip=CKV_AWS_18: Access logging not required
  # checkov:skip=CKV_AWS_21: Versioning not required
  # checkov:skip=CKV2_AWS_62: Event notifications not required
  bucket        = "forms-${local.env}-reliability-file-storage"
  force_destroy = var.env == "development"
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
    filter {}

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

resource "aws_s3_bucket_cors_configuration" "reliability_file_storage" {
  bucket = aws_s3_bucket.reliability_file_storage.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["POST"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
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
  bucket        = "forms-${local.env}-vault-file-storage"
  force_destroy = var.env == "development"
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
  bucket        = "forms-${local.env}-archive-storage"
  force_destroy = var.env == "development"
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
    filter {}

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

#
# Audit Logs archive storage
#

resource "aws_s3_bucket" "audit_logs_archive_storage" {
  # checkov:skip=CKV_AWS_18: Access logging not required
  # checkov:skip=CKV_AWS_21: Versioning not required
  # checkov:skip=CKV2_AWS_62: Event notifications not required
  bucket        = "forms-${local.env}-audit-logs-archive-storage"
  force_destroy = var.env == "development"
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
    filter {}

    expiration {
      days = 700
    }
  }
}

#
# Prisma Migration storage
#

resource "aws_s3_bucket" "prisma_migration_storage" {
  # checkov:skip=CKV_AWS_18: Access logging not required
  # checkov:skip=CKV_AWS_21: Versioning not required
  # checkov:skip=CKV2_AWS_62: Event notifications not required
  # checkov:skip=CKV2_AWS_61: Lifecycle configuration not required
  bucket        = "forms-${local.env}-prisma-migration-storage"
  force_destroy = var.env == "development"
}

resource "aws_s3_bucket_ownership_controls" "prisma_migration_storage" {
  bucket = aws_s3_bucket.prisma_migration_storage.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "prisma_migration_storage" {
  bucket = aws_s3_bucket.prisma_migration_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "prisma_migration_storage" {
  bucket                  = aws_s3_bucket.prisma_migration_storage.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}