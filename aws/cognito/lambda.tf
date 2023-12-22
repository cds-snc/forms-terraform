########################
# COGNITO EMAIL SENDER
########################

data "archive_file" "cognito_email_sender_code" {
  type        = "zip"
  source_dir  = "lambda/cognito_email_sender/dist"
  output_path = "/tmp/cognito_email_sender.zip"
}

resource "aws_s3_object" "cognito_email_sender_code" {
  bucket      = var.lambda_code_id
  key         = "cognito_email_sender_code"
  source      = data.archive_file.cognito_email_sender_code.output_path
  source_hash = data.archive_file.cognito_email_sender_code.output_base64sha256
}

resource "aws_lambda_function" "cognito_email_sender" {
  s3_bucket         = aws_s3_object.cognito_email_sender_code.bucket
  s3_key            = aws_s3_object.cognito_email_sender_code.key
  s3_object_version = aws_s3_object.cognito_email_sender_code.version_id
  function_name = "Cognito_Email_Sender"
  role          = aws_iam_role.cognito_lambda.arn
  handler       = "cognito_email_sender.handler"
  timeout       = 300

  source_code_hash = data.archive_file.cognito_email_sender_code.output_base64sha256

  runtime = "nodejs18.x"
  layers  = [aws_lambda_layer_version.cognito_email_sender_nodejs.arn]

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

  runtime = "nodejs18.x"

  tracing_config {
    mode = "PassThrough"
  }



}
resource "aws_cloudwatch_log_group" "cognito_pre_sign_up" {
  name              = "/aws/lambda/${aws_lambda_function.cognito_pre_sign_up.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}