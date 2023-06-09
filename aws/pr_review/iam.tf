resource "aws_iam_role" "forms_lambda_client" {
  count              = var.env == "staging" ? 1 : 0
  name               = "forms-lambda-client"
  assume_role_policy = data.aws_iam_policy_document.forms_lambda_client.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

data "aws_iam_policy_document" "forms_lambda_client" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "secrets_manager_forms_lambda_client" {
  count      = var.env == "staging" ? 1 : 0
  role       = aws_iam_role.forms_lambda_client[0].name
  policy_arn = var.ecs_iam_forms_secrets_manager_policy_arn
}

resource "aws_iam_role_policy_attachment" "kms_forms_lambda_client" {
  count      = var.env == "staging" ? 1 : 0
  role       = aws_iam_role.forms_lambda_client[0].name
  policy_arn = var.ecs_iam_forms_kms_policy_arn
}

resource "aws_iam_role_policy_attachment" "s3_forms_lambda_client" {
  count      = var.env == "staging" ? 1 : 0
  role       = aws_iam_role.forms_lambda_client[0].name
  policy_arn = var.ecs_iam_forms_s3_policy_arn
}

resource "aws_iam_role_policy_attachment" "dynamodb_forms_lambda_client" {
  count      = var.env == "staging" ? 1 : 0
  role       = aws_iam_role.forms_lambda_client[0].name
  policy_arn = var.ecs_iam_forms_dynamodb_policy_arn
}

resource "aws_iam_role_policy_attachment" "sqs_forms_lambda_client" {
  count      = var.env == "staging" ? 1 : 0
  role       = aws_iam_role.forms_lambda_client[0].name
  policy_arn = var.ecs_iam_forms_sqs_policy_arn
}

resource "aws_iam_role_policy_attachment" "cognito_forms_lambda_client" {
  count      = var.env == "staging" ? 1 : 0
  role       = aws_iam_role.forms_lambda_client[0].name
  policy_arn = var.ecs_iam_forms_cognito_policy_arn
}

resource "aws_iam_role_policy_attachment" "forms_lambda_client_vpc_access" {
  count      = var.env == "staging" ? 1 : 0
  role       = aws_iam_role.forms_lambda_client[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
