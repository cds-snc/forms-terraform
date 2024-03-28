resource "aws_iam_role" "cognito_lambda" {
  name               = "iam_for_cognito_lambda"
  assume_role_policy = data.aws_iam_policy_document.cognito_lambda_assume.json
}

data "aws_iam_policy_document" "cognito_lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "cognito_lambda_logging" {
  name        = "cognito_lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a cognito lambda"
  policy      = data.aws_iam_policy_document.cognito_lambda_logging.json
}

data "aws_iam_policy_document" "cognito_lambda_logging" {
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

# Allow access to lambda to encrypt and decrypt data.
resource "aws_iam_policy" "cognito_lambda_kms" {
  name        = "cognito_lambda_kms"
  path        = "/"
  description = "IAM policy for storing encrypting and decrypting data"
  policy      = data.aws_iam_policy_document.cognito_lambda_kms.json
}

data "aws_iam_policy_document" "cognito_lambda_kms" {
  statement {
    effect = "Allow"

    actions = [
      "kms:GenerateDataKey",
      "kms:Encrypt",
      "kms:Decrypt"
    ]

    resources = [
      aws_kms_key.cognito_encryption.arn
    ]
  }
}

# Allow access to lambda to secrets manager.
resource "aws_iam_policy" "cognito_lambda_secrets" {
  name        = "cognito_lambda_secrets"
  path        = "/"
  description = "IAM policy for accessing secret manager"
  policy      = data.aws_iam_policy_document.cognito_lambda_secrets.json
}

data "aws_iam_policy_document" "cognito_lambda_secrets" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      var.notify_api_key_secret_arn
    ]
  }
}

resource "aws_iam_role_policy_attachment" "cognito_lambda_logs" {
  role       = aws_iam_role.cognito_lambda.name
  policy_arn = aws_iam_policy.cognito_lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "cognito_lambda_kms" {
  role       = aws_iam_role.cognito_lambda.name
  policy_arn = aws_iam_policy.cognito_lambda_kms.arn
}

resource "aws_iam_role_policy_attachment" "cognito_lambda_secrets" {
  role       = aws_iam_role.cognito_lambda.name
  policy_arn = aws_iam_policy.cognito_lambda_secrets.arn
}