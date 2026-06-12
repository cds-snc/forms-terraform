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

  attribute {
    name = "HasFileKeys"
    type = "N"
  }

  attribute {
    name = "CreatedAt"
    type = "N"
  }

  global_secondary_index {
    name = "HasFileKeysByCreatedAt"

    key_schema {
      attribute_name = "HasFileKeys"
      key_type       = "HASH"
    }

    key_schema {
      attribute_name = "CreatedAt"
      key_type       = "RANGE"
    }

    projection_type    = "INCLUDE"
    non_key_attributes = ["SubmissionID", "SendReceipt", "NotifyProcessed", "FileKeys"]
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

  attribute {
    name = "Status#CreatedAt"
    type = "S"
  }

  # Legacy StatusCreatedAt GSI (now replaced with StatusCreatedAt_v2). We can delete it once both GC Forms APP and API use v2.
  global_secondary_index {
    name               = "StatusCreatedAt"
    hash_key           = "FormID"
    range_key          = "Status#CreatedAt"
    projection_type    = "INCLUDE"
    non_key_attributes = ["CreatedAt", "Name"]
  }

  global_secondary_index {
    name = "StatusCreatedAt_v2"

    key_schema {
      attribute_name = "FormID"
      key_type       = "HASH"
    }

    key_schema {
      attribute_name = "Status#CreatedAt"
      key_type       = "RANGE"
    }

    projection_type    = "INCLUDE"
    non_key_attributes = ["CreatedAt", "Name", "VersionId"]
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_dynamodb_arn
  }

  point_in_time_recovery {
    enabled = var.env != "development"
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

  attribute {
    name = "TimeStamp"
    type = "N"
  }

  attribute {
    name = "Status"
    type = "S"
  }

  attribute {
    name = "Subject"
    type = "S"
  }

  global_secondary_index {
    name = "UserByTime"

    key_schema {
      attribute_name = "UserID"
      key_type       = "HASH"
    }

    key_schema {
      attribute_name = "TimeStamp"
      key_type       = "RANGE"
    }

    projection_type = "KEYS_ONLY"
  }

  global_secondary_index {
    name = "StatusByTimestamp"

    key_schema {
      attribute_name = "Status"
      key_type       = "HASH"
    }

    key_schema {
      attribute_name = "TimeStamp"
      key_type       = "RANGE"
    }

    projection_type = "ALL"
  }

  global_secondary_index {
    name = "SubjectByTimestamp"

    key_schema {
      attribute_name = "Subject"
      key_type       = "HASH"
    }

    key_schema {
      attribute_name = "TimeStamp"
      key_type       = "RANGE"
    }

    projection_type = "KEYS_ONLY"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_dynamodb_arn
  }

  point_in_time_recovery {
    enabled = var.env != "development"
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

  attribute {
    name = "TimeStamp"
    type = "N"
  }

  attribute {
    name = "Status"
    type = "S"
  }

  attribute {
    name = "Subject"
    type = "S"
  }

  global_secondary_index {
    name = "UserByTime"

    key_schema {
      attribute_name = "UserID"
      key_type       = "HASH"
    }

    key_schema {
      attribute_name = "TimeStamp"
      key_type       = "RANGE"
    }

    projection_type = "KEYS_ONLY"
  }

  global_secondary_index {
    name = "StatusByTimestamp"

    key_schema {
      attribute_name = "Status"
      key_type       = "HASH"
    }

    key_schema {
      attribute_name = "TimeStamp"
      key_type       = "RANGE"
    }

    projection_type = "ALL"
  }


  global_secondary_index {
    name = "SubjectByTimestamp"

    key_schema {
      attribute_name = "Subject"
      key_type       = "HASH"
    }

    key_schema {
      attribute_name = "TimeStamp"
      key_type       = "RANGE"
    }

    projection_type = "KEYS_ONLY"
  }


  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_dynamodb_arn
  }

  point_in_time_recovery {
    enabled = var.env != "development"
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
