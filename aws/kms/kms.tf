#
# KMS:
# The Customer Managed Keys (CMKs) used for data encryption/decryption
#
resource "aws_kms_key" "cloudwatch" {
  description         = "CloudWatch Log Group Key"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_cloudwatch.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_kms_key" "cloudwatch_us_east" {
  provider = aws.us-east-1

  description         = "CloudWatch Log Group Key"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_cloudwatch.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

data "aws_iam_policy_document" "kms_cloudwatch" {
  # checkov:skip=CKV_AWS_109: `resources = ["*"]` identifies the KMS key to which the key policy is attached
  # checkov:skip=CKV_AWS_111: `resources = ["*"]` identifies the KMS key to which the key policy is attached
  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${var.region}.amazonaws.com"]
    }
  }

  statement {
    sid    = "Allow_CloudWatch_for_CMK"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
  }

  statement {
    sid    = "CloudwatchEvents"
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }

}

resource "aws_kms_key" "dynamo_db" {
  description         = "KMS key for DynamoDB encryption"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_dynamo_db.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

data "aws_iam_policy_document" "kms_dynamo_db" {
  # checkov:skip=CKV_AWS_109: `resources = ["*"]` identifies the KMS key to which the key policy is attached
  # checkov:skip=CKV_AWS_111: `resources = ["*"]` identifies the KMS key to which the key policy is attached
  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }
  }

  statement {
    sid    = "Allow access through Amazon DynamoDB for all principals in the account that are authorized to use Amazon DynamoDB"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["dynamodb.*.amazonaws.com"]
    }
  }

  statement {
    sid    = "Allow DynamoDB to get information about the CMK"
    effect = "Allow"
    actions = [
      "kms:Describe*",
      "kms:Get*",
      "kms:List*"
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["dynamodb.amazonaws.com"]
    }
  }
}