resource "aws_dynamodb_table" "reliability_queue" {
  name           = "ReliabilityQueue"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "SubmissionID"
  stream_enabled = false

  attribute {
    name = "SubmissionID"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_dynamodb_arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_dynamodb_table" "vault" {
  name           = "Vault"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "FormID"
  range_key      = "SubmissionID"
  stream_enabled = false

  attribute {
    name = "FormID"
    type = "S"
  }

  attribute {
    name = "SubmissionID"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_dynamodb_arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}
