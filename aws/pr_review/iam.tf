resource "aws_iam_role" "forms_lambda_client" {
  name               = "forms-lambda-client"
  assume_role_policy = data.aws_iam_policy_document.forms_lambda_client.json

  tags = var.core_tags
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
  role       = aws_iam_role.forms_lambda_client.name
  policy_arn = var.ecs_iam_forms_secrets_manager_policy_arn
}

resource "aws_iam_role_policy_attachment" "kms_forms_lambda_client" {
  role       = aws_iam_role.forms_lambda_client.name
  policy_arn = var.ecs_iam_forms_kms_policy_arn
}

resource "aws_iam_role_policy_attachment" "dynamodb_forms_lambda_client" {
  role       = aws_iam_role.forms_lambda_client.name
  policy_arn = var.ecs_iam_forms_dynamodb_policy_arn
}

resource "aws_iam_role_policy_attachment" "sqs_forms_lambda_client" {
  role       = aws_iam_role.forms_lambda_client.name
  policy_arn = var.ecs_iam_forms_sqs_policy_arn
}

resource "aws_iam_role_policy_attachment" "forms_lambda_audit_logs" {
  role       = aws_iam_role.forms_lambda_client.name
  policy_arn = var.ecs_iam_forms_audit_logs_arn
}

resource "aws_iam_role_policy_attachment" "cognito_forms_lambda_client" {
  role       = aws_iam_role.forms_lambda_client.name
  policy_arn = var.ecs_iam_forms_cognito_policy_arn
}

resource "aws_iam_role_policy_attachment" "forms_lambda_client_vpc_access" {
  role       = aws_iam_role.forms_lambda_client.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "forms_lambda_parameter_store" {
  statement {
    actions = ["ssm:GetParameters"]
    effect  = "Allow"
    resources = [
      "arn:aws:ssm:ca-central-1:${var.account_id}:parameter/form-viewer/env"
    ]
  }
}

resource "aws_iam_policy" "forms_lambda_parameter_store" {
  name   = "formsLambdaParameterStoreRetrieval"
  path   = "/"
  policy = data.aws_iam_policy_document.forms_lambda_parameter_store.json

  tags = var.core_tags
}

resource "aws_iam_role_policy_attachment" "forms_lambda_parameter_store" {
  role       = aws_iam_role.forms_lambda_client.name
  policy_arn = aws_iam_policy.forms_lambda_parameter_store.arn
}
