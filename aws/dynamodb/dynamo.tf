resource "aws_dynamodb_table" "reliability_queue" {
  # checkov:skip=CKV_AWS_28: 'point in time recovery' is set to true for staging and production
  name                        = "ReliabilityQueue"
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "SubmissionID"
  deletion_protection_enabled = var.env != "development"

  attribute {
    name = "SubmissionID"
    type = "S"
  }

  ttl {
    enabled        = true
    attribute_name = "TTL"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_dynamodb_arn
  }

  point_in_time_recovery {
    enabled = var.env != "development"
  }
}

resource "aws_dynamodb_global_secondary_index" "reliability_queue_has_file_keys_by_created_at" {
  index_name = "HasFileKeysByCreatedAt"
  table_name = aws_dynamodb_table.reliability_queue.name

  key_schema {
    attribute_name = "HasFileKeys"
    attribute_type = "N"
    key_type       = "HASH"
  }

  key_schema {
    attribute_name = "CreatedAt"
    attribute_type = "N"
    key_type       = "RANGE"
  }

  projection {
    projection_type    = "INCLUDE"
    non_key_attributes = ["SubmissionID", "SendReceipt", "NotifyProcessed", "FileKeys"]
  }
}

resource "aws_dynamodb_table" "vault" {
  # checkov:skip=CKV_AWS_28: 'point in time recovery' is set to true for staging and production
  name                        = "Vault"
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "FormID"
  range_key                   = "NAME_OR_CONF"
  stream_enabled              = true
  stream_view_type            = "NEW_AND_OLD_IMAGES"
  deletion_protection_enabled = var.env != "development"

  attribute {
    name = "FormID"
    type = "S"
  }

  attribute {
    name = "NAME_OR_CONF"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_dynamodb_arn
  }

  point_in_time_recovery {
    enabled = var.env != "development"
  }

  lifecycle {
    ignore_changes = [global_secondary_index]
  }
}

resource "aws_dynamodb_global_secondary_index" "vault_status_created_at" {
  index_name = "StatusCreatedAt"
  table_name = aws_dynamodb_table.vault.name

  key_schema {
    attribute_name = "FormID"
    attribute_type = "S"
    key_type       = "HASH"
  }

  key_schema {
    attribute_name = "Status#CreatedAt"
    attribute_type = "S"
    key_type       = "RANGE"
  }

  projection {
    projection_type    = "INCLUDE"
    non_key_attributes = ["CreatedAt", "Name"]
  }
}

resource "aws_dynamodb_global_secondary_index" "vault_status_created_at_v2" {
  count = var.env == "production" ? 0 : 1 # disabled in Production as it is used to design and test the new form versioning system

  index_name = "StatusCreatedAt_v2"
  table_name = aws_dynamodb_table.vault.name

  key_schema {
    attribute_name = "FormID"
    attribute_type = "S"
    key_type       = "HASH"
  }

  key_schema {
    attribute_name = "Status#CreatedAt"
    attribute_type = "S"
    key_type       = "RANGE"
  }

  projection {
    projection_type    = "INCLUDE"
    non_key_attributes = ["CreatedAt", "Name", "Version"]
  }
}

resource "aws_dynamodb_table" "audit_logs" {
  # checkov:skip=CKV_AWS_28: 'point in time recovery' is set to true for staging and production
  name                        = "AuditLogs"
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "UserID"
  range_key                   = "Event#SubjectID#TimeStamp"
  deletion_protection_enabled = var.env != "development"
  stream_enabled              = false # Can be removed in the future when this gets applied to production

  attribute {
    name = "UserID"
    type = "S"
  }

  attribute {
    name = "Event#SubjectID#TimeStamp"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_dynamodb_arn
  }

  point_in_time_recovery {
    enabled = var.env != "development"
  }
}

resource "aws_dynamodb_global_secondary_index" "audit_logs_user_by_time" {
  index_name = "UserByTime"
  table_name = aws_dynamodb_table.audit_logs.name

  key_schema {
    attribute_name = "UserID"
    attribute_type = "S"
    key_type       = "HASH"
  }

  key_schema {
    attribute_name = "TimeStamp"
    attribute_type = "N"
    key_type       = "RANGE"
  }

  projection {
    projection_type = "KEYS_ONLY"
  }
}

resource "aws_dynamodb_global_secondary_index" "audit_logs_status_by_timestamp" {
  index_name = "StatusByTimestamp"
  table_name = aws_dynamodb_table.audit_logs.name

  key_schema {
    attribute_name = "Status"
    attribute_type = "S"
    key_type       = "HASH"
  }

  key_schema {
    attribute_name = "TimeStamp"
    attribute_type = "N"
    key_type       = "RANGE"
  }

  projection {
    projection_type = "ALL"
  }
}

resource "aws_dynamodb_global_secondary_index" "audit_logs_subject_by_timestamp" {
  index_name = "SubjectByTimestamp"
  table_name = aws_dynamodb_table.audit_logs.name

  key_schema {
    attribute_name = "Subject"
    attribute_type = "S"
    key_type       = "HASH"
  }

  key_schema {
    attribute_name = "TimeStamp"
    attribute_type = "N"
    key_type       = "RANGE"
  }

  projection {
    projection_type = "KEYS_ONLY"
  }
}

resource "aws_dynamodb_table" "api_audit_logs" {
  # checkov:skip=CKV_AWS_28: 'point in time recovery' is set to true for staging and production
  name                        = "ApiAuditLogs"
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "UserID"
  range_key                   = "Event#SubjectID#TimeStamp"
  deletion_protection_enabled = var.env != "development"
  stream_enabled              = false # Can be removed in the future when this gets applied to production

  attribute {
    name = "UserID"
    type = "S"
  }

  attribute {
    name = "Event#SubjectID#TimeStamp"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_dynamodb_arn
  }

  point_in_time_recovery {
    enabled = var.env != "development"
  }
}

resource "aws_dynamodb_global_secondary_index" "api_audit_logs_user_by_time" {
  index_name = "UserByTime"
  table_name = aws_dynamodb_table.api_audit_logs.name

  key_schema {
    attribute_name = "UserID"
    attribute_type = "S"
    key_type       = "HASH"
  }

  key_schema {
    attribute_name = "TimeStamp"
    attribute_type = "N"
    key_type       = "RANGE"
  }

  projection {
    projection_type = "KEYS_ONLY"
  }
}

resource "aws_dynamodb_global_secondary_index" "api_audit_logs_status_by_timestamp" {
  index_name = "StatusByTimestamp"
  table_name = aws_dynamodb_table.api_audit_logs.name

  key_schema {
    attribute_name = "Status"
    attribute_type = "S"
    key_type       = "HASH"
  }

  key_schema {
    attribute_name = "TimeStamp"
    attribute_type = "N"
    key_type       = "RANGE"
  }

  projection {
    projection_type = "ALL"
  }
}

resource "aws_dynamodb_global_secondary_index" "api_audit_logs_subject_by_timestamp" {
  index_name = "SubjectByTimestamp"
  table_name = aws_dynamodb_table.api_audit_logs.name

  key_schema {
    attribute_name = "Subject"
    attribute_type = "S"
    key_type       = "HASH"
  }

  key_schema {
    attribute_name = "TimeStamp"
    attribute_type = "N"
    key_type       = "RANGE"
  }

  projection {
    projection_type = "KEYS_ONLY"
  }
}

resource "aws_dynamodb_table" "notification" {
  # checkov:skip=CKV_AWS_28: 'point in time recovery' is set to true for staging and production
  name                        = "Notification"
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "NotificationID"
  deletion_protection_enabled = var.env != "development"

  attribute {
    name = "NotificationID"
    type = "S"
  }

  ttl {
    enabled        = true
    attribute_name = "TTL"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_dynamodb_arn
  }

  point_in_time_recovery {
    enabled = var.env != "development"
  }
}
