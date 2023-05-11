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

resource "aws_lambda_layer_version" "cognito_email_sender_nodejs" {
  filename            = "/tmp/cognito_email_sender_nodejs.zip"
  layer_name          = "cognito_email_sender_node_packages"
  source_code_hash    = data.archive_file.cognito_email_sender_nodejs.output_base64sha256
  compatible_runtimes = ["nodejs16.x"]
}

#################################
# Define Auth Challenge
#################################

data "archive_file" "define_auth_challenge_main" {
  type        = "zip"
  source_file = "lambda/define_auth_challenge/define_auth_challenge.js"
  output_path = "/tmp/define_auth_challenge_main.zip"
}

resource "aws_lambda_function" "define_auth_challenge" {
  filename      = "/tmp/define_auth_challenge_main.zip"
  function_name = "Cognito_Define_Auth_Challenge"
  role          = aws_iam_role.cognito_lambda.arn
  handler       = "define_auth_challenge.handler"
  timeout       = 60

  source_code_hash = data.archive_file.define_auth_challenge_main.output_base64sha256

  runtime = "nodejs16.x"

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

#################################
# Create Auth Challenge
#################################

data "archive_file" "create_auth_challenge_main" {
  type        = "zip"
  source_file = "lambda/create_auth_challenge/create_auth_challenge.js"
  output_path = "/tmp/create_auth_challenge_main.zip"
}

data "archive_file" "create_auth_challenge_nodejs" {
  type        = "zip"
  source_dir  = "lambda/create_auth_challenge"
  excludes    = ["create_auth_challenge.js"]
  output_path = "/tmp/create_auth_challenge_nodejs.zip"
}

resource "aws_lambda_function" "create_auth_challenge" {
  filename      = "/tmp/create_auth_challenge_main.zip"
  function_name = "Cognito_Create_Auth_Challenge"
  role          = aws_iam_role.cognito_lambda.arn
  handler       = "create_auth_challenge.handler"
  timeout       = 60

  source_code_hash = data.archive_file.create_auth_challenge_main.output_base64sha256

  runtime = "nodejs16.x"
  layers  = [aws_lambda_layer_version.create_auth_challenge_nodejs.arn]

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_lambda_layer_version" "create_auth_challenge_nodejs" {
  filename            = "/tmp/verify_create_auth_challenge_nodejs.zip"
  layer_name          = "create_auth_challenge_node_packages"
  source_code_hash    = data.archive_file.create_auth_challenge_nodejs.output_base64sha256
  compatible_runtimes = ["nodejs16.x"]
}


#################################
# Verify Auth Challenge
#################################

data "archive_file" "verify_auth_challenge_main" {
  type        = "zip"
  source_file = "lambda/verify_auth_challenge/verify_auth_challenge.js"
  output_path = "/tmp/verify_auth_challenge_main.zip"
}

resource "aws_lambda_function" "verify_auth_challenge" {
  filename      = "/tmp/verify_auth_challenge_main.zip"
  function_name = "Cognito_Verify_Auth_Challenge"
  role          = aws_iam_role.cognito_lambda.arn
  handler       = "verify_auth_challenge.handler"
  timeout       = 60

  source_code_hash = data.archive_file.verify_auth_challenge_main.output_base64sha256

  runtime = "nodejs16.x"

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}