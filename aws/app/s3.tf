#
# Reliability Queue File Storage
#
resource "aws_s3_bucket" "reliability_file_storage" {
  # checkov:skip=CKV_AWS_18: Versioning not required
  # checkov:skip=CKV_AWS_21: Access logging not required  
  bucket = "forms-${var.env}-reliability-file-storage"

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_s3_bucket_acl" "reliability_file_storage" {
  bucket = aws_s3_bucket.reliability_file_storage.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reliability_file_storage" {
  bucket = aws_s3_bucket.reliability_file_storage.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "reliability_file_storage" {
  bucket = aws_s3_bucket.reliability_file_storage.id

  rule {
    id     = "Keep files for 30 days"
    status = "Enabled"
    expiration {
      days = 30
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
  # checkov:skip=CKV_AWS_21: Access logging not required  
  bucket = "forms-${var.env}-vault-file-storage"

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_s3_bucket_versioning" "vault_file_storage" {
  bucket = aws_s3_bucket.vault_file_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "vault_file_storage" {
  bucket = aws_s3_bucket.vault_file_storage.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reliability_file_storage" {
  bucket = aws_s3_bucket.reliability_file_storage.id
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
  # checkov:skip=CKV_AWS_18: Versioning not required
  # checkov:skip=CKV_AWS_21: Access logging not required
  bucket = "forms-${var.env}-archive-storage"

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_s3_bucket_acl" "archive_storage" {
  bucket = aws_s3_bucket.archive_storage.id
  acl    = "private"
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
  bucket = aws_s3_bucket.archive_storage.id

  rule {
    id     = "Keep files for 30 days"
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