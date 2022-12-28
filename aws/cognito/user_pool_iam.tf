resource "aws_iam_role" "cognito_userpool_import" {
  name               = "role_for_cognito_user_pool_import"
  assume_role_policy = data.aws_iam_policy_document.cognito_userpool_import_assume.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

data "aws_iam_policy_document" "cognito_userpool_import_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cognito-idp.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "cognito_userpool_import_logging" {
  name        = "cognito_userpool_import_logging"
  path        = "/"
  description = "IAM policy for logging from a cognito userpool import"
  policy      = data.aws_iam_policy_document.cognito_userpool_import_logging.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}


data "aws_iam_policy_document" "cognito_userpool_import_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}