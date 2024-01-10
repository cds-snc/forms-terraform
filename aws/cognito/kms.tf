resource "aws_kms_key" "cognito_encryption" {
  description         = "Key used by AWS Cognito to encrypt data sent to lambda triggers"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_cognito_encryption.json


}

resource "aws_kms_alias" "cognito_encryption_alias" {
  name          = "alias/cognito-encryption-key"
  target_key_id = aws_kms_key.cognito_encryption.key_id
}

data "aws_iam_policy_document" "kms_cognito_encryption" {
  # checkov:skip=CKV_AWS_109: `resources = ["*"]` identifies the KMS key to which the key policy is attached
  # checkov:skip=CKV_AWS_111: `resources = ["*"]` identifies the KMS key to which the key policy is attached
  # checkov:skip=CKV_AWS_356: `resources = ["*"]` identifies the KMS key to which the key policy is attached
  // TODO: refactor write access (then we can remove checkov:skip=CKV_AWS_111)
  // TODO: refactor to remove `resources = ["*"]` (then we can remove checkov:skip=CKV_AWS_356)

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
    sid    = "Enable Cognito Access to KMS key"
    effect = "Allow"
    actions = [
      "kms:CreateGrant"
    ]
    resources = ["*"]

    principals {
      identifiers = ["cognito-idp.amazonaws.com"]
      type        = "Service"
    }
  }

}