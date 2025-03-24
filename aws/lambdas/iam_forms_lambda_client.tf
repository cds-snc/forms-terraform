resource "aws_iam_role" "forms_lambda_client" {
  name               = "forms-lambda-client"
  assume_role_policy = data.aws_iam_policy_document.forms_lambda_client.json
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

resource "aws_iam_role_policy_attachment" "s3_forms_lambda_client" {
  role       = aws_iam_role.forms_lambda_client.name
  policy_arn = var.ecs_iam_forms_s3_policy_arn
}

resource "aws_iam_role_policy_attachment" "dynamodb_forms_lambda_client" {
  role       = aws_iam_role.forms_lambda_client.name
  policy_arn = var.ecs_iam_forms_dynamodb_policy_arn
}

resource "aws_iam_role_policy_attachment" "sqs_forms_lambda_client" {
  role       = aws_iam_role.forms_lambda_client.name
  policy_arn = var.ecs_iam_forms_sqs_policy_arn
}

resource "aws_iam_role_policy_attachment" "cognito_forms_lambda_client" {
  role       = aws_iam_role.forms_lambda_client.name
  policy_arn = var.ecs_iam_forms_cognito_policy_arn
}

resource "aws_iam_role_policy_attachment" "forms_lambda_client_vpc_access" {
  role       = aws_iam_role.forms_lambda_client.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_permission" "submission_lambda_invoke" {
  statement_id  = "AllowSubmissionInvokeFromFormsLambdaClient"
  action        = "lambda:InvokeFunction"
  principal     = aws_iam_role.forms_lambda_client.arn
  function_name = aws_lambda_function.submission.function_name
}
