resource "aws_dynamodb_table" "reliability_queue" {
  name         = "ReliabilityQueue"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "SubmissionID"

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

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_dynamodb_table" "vault" {
  name         = "Vault"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "FormID"
  range_key    = "NAME_OR_CONF"

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

  attribute {
    name = "RemovalDate"
    type = "N"
  }

  attribute {
    name = "CreatedAt"
    type = "N"
  }

  global_secondary_index {
    name            = "Status"
    hash_key        = "FormID"
    range_key       = "Status"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "Archive"
    hash_key        = "Status"
    range_key       = "RemovalDate"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "Nagware"
    hash_key        = "Status"
    range_key       = "CreatedAt"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_dynamodb_arn
  }

  point_in_time_recovery {
    enabled = var.env == "local" ? false : true
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_dynamodb_table" "audit_logs" {
  name             = "AuditLogs"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "UserID"
  range_key        = "Event#SubjectID#TimeStamp"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

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

  global_secondary_index {
    name            = "UserByTime"
    hash_key        = "UserID"
    range_key       = "TimeStamp"
    projection_type = "KEYS_ONLY"
  }

  ttl {
    enabled        = true
    attribute_name = "ArchiveDate"
  }


  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_dynamodb_arn
  }

  point_in_time_recovery {
    enabled = var.env == "local" ? false : true
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}
