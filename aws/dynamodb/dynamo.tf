resource "aws_dynamodb_table" "reliability_queue" {
  name                        = "ReliabilityQueue"
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "SubmissionID"
  deletion_protection_enabled = true

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
    enabled = var.env == "local" ? false : true
  }
}

resource "aws_dynamodb_table" "vault" {
  name                        = "Vault"
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "FormID"
  range_key                   = "NAME_OR_CONF"
  stream_enabled              = true
  stream_view_type            = "NEW_AND_OLD_IMAGES"
  deletion_protection_enabled = true

  attribute {
    name = "FormID"
    type = "S"
  }

  attribute {
    name = "NAME_OR_CONF"
    type = "S"
  }

  attribute {
    name = "Status"
    type = "S"
  }

  global_secondary_index {
    name            = "Status"
    hash_key        = "FormID"
    range_key       = "Status"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_dynamodb_arn
  }

  point_in_time_recovery {
    enabled = var.env == "local" ? false : true
  }
}

resource "aws_dynamodb_table" "audit_logs" {
  name                        = "AuditLogs"
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "UserID"
  range_key                   = "Event#SubjectID#TimeStamp"
  deletion_protection_enabled = true
  stream_enabled              = false # Can be removed in the future when this gets applied to production

  attribute {
    name = "UserID"
    type = "S"
  }

  attribute {
    name = "Event#SubjectID#TimeStamp"
    type = "S"
  }

  attribute {
    name = "TimeStamp"
    type = "N"
  }

  attribute {
    name = "Status"
    type = "S"
  }

  global_secondary_index {
    name            = "UserByTime"
    hash_key        = "UserID"
    range_key       = "TimeStamp"
    projection_type = "KEYS_ONLY"
  }

  global_secondary_index {
    name            = "StatusByTimestamp"
    hash_key        = "Status"
    range_key       = "TimeStamp"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_dynamodb_arn
  }

  point_in_time_recovery {
    enabled = var.env == "local" ? false : true
  }
}
