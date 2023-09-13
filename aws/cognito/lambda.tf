########################
# COGNITO EMAIL SENDER
########################

data "archive_file" "cognito_email_sender_main" {
  type        = "zip"
  source_file = "lambda/cognito_email_sender/cognito_email_sender.js"
  output_path = "/tmp/cognito_email_sender_main.zip"
}

data "archive_file" "cognito_email_sender_nodejs" {
  type        = "zip"
  source_dir  = "lambda/cognito_email_sender"
  excludes    = ["cognito_email_sender.js"]
  output_path = "/tmp/cognito_email_sender_nodejs.zip"
}

resource "aws_lambda_function" "cognito_email_sender" {
  filename      = "/tmp/cognito_email_sender_main.zip"
  function_name = "Cognito_Email_Sender"
  role          = aws_iam_role.cognito_lambda.arn
  handler       = "cognito_email_sender.handler"
  timeout       = 300

  source_code_hash = data.archive_file.cognito_email_sender_main.output_base64sha256

  runtime = "nodejs16.x"
  layers  = [aws_lambda_layer_version.cognito_email_sender_nodejs.arn]

  environment {
    variables = {
      NOTIFY_API_KEY = aws_secretsmanager_secret_version.cognito_notify_api_key.secret_string
      TEMPLATE_ID    = var.cognito_code_template_id
      KEY_ARN        = aws_kms_key.cognito_encryption.arn
      KEY_ALIAS      = aws_kms_alias.cognito_encryption_alias.arn
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_cloudwatch_log_group" "cognito_email_sender" {
  name              = "/aws/lambda/${aws_lambda_function.cognito_email_sender.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 90
}

resource "aws_lambda_layer_version" "cognito_email_sender_nodejs" {
  filename            = "/tmp/cognito_email_sender_nodejs.zip"
  layer_name          = "cognito_email_sender_node_packages"
  source_code_hash    = data.archive_file.cognito_email_sender_nodejs.output_base64sha256
  compatible_runtimes = ["nodejs16.x"]
}

########################
# PRE SIGN UP
########################

data "archive_file" "cognito_pre_sign_up_main" {
  type        = "zip"
  source_file = "lambda/pre_sign_up/pre_sign_up.js"
  output_path = "/tmp/pre_sign_up_main.zip"
}

resource "aws_lambda_function" "cognito_pre_sign_up" {
  filename      = "/tmp/pre_sign_up_main.zip"
  function_name = "Cognito_Pre_Sign_Up"
  role          = aws_iam_role.cognito_lambda.arn
  handler       = "pre_sign_up.handler"
  timeout       = 300

  source_code_hash = data.archive_file.cognito_pre_sign_up_main.output_base64sha256

  runtime = "nodejs16.x"

  tracing_config {
    mode = "PassThrough"
  }


  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}
resource "aws_cloudwatch_log_group" "cognito_pre_sign_up" {
  name              = "/aws/lambda/${aws_lambda_function.cognito_pre_sign_up.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 90
}