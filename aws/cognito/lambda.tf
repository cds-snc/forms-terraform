########################
# COGNITO EMAIL SENDER
########################

resource "aws_lambda_function" "cognito_email_sender" {
  function_name = "cognito-email-sender"
  image_uri     = "${var.ecr_repository_url_cognito_email_sender_lambda}:latest"
  package_type  = "Image"
  role          = aws_iam_role.cognito_lambda.arn
  timeout       = 300

  environment {
    variables = {
      NOTIFY_API_KEY = var.notify_api_key_secret_arn
      TEMPLATE_ID    = var.cognito_code_template_id
      KEY_ARN        = aws_kms_key.cognito_encryption.arn
      KEY_ALIAS      = aws_kms_alias.cognito_encryption_alias.arn
    }
  }

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_cloudwatch_log_group" "cognito_email_sender" {
  name              = "/aws/lambda/${aws_lambda_function.cognito_email_sender.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}

########################
# PRE SIGN UP
########################

resource "aws_lambda_function" "cognito_pre_sign_up" {
  function_name = "cognito-pre-sign-up"
  image_uri     = "${var.ecr_repository_url_cognito_pre_sign_up_lambda}:latest"
  package_type  = "Image"
  role          = aws_iam_role.cognito_lambda.arn
  timeout       = 300

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_cloudwatch_log_group" "cognito_pre_sign_up" {
  name              = "/aws/lambda/${aws_lambda_function.cognito_pre_sign_up.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}