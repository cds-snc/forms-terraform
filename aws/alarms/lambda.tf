#
# Lambda - Notify Slack and OpsGenie
#
data "archive_file" "notify_slack_code" {
  type        = "zip"
  source_dir  = "lambda/notify_slack/dist"
  output_path = "/tmp/notify_slack_code.zip"
}
resource "aws_s3_object" "notify_slack_code_code" {
  bucket      = var.lambda_code_id
  key         = "notify_slack_code_code"
  source      = data.archive_file.notify_slack_code_code.output_path
  source_hash = data.archive_file.notify_slack_code_code.output_base64sha256
}

#tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "notify_slack" {
  s3_bucket         = aws_s3_object.notify_slack_code.bucket
  s3_key            = aws_s3_object.notify_slack_code.key
  s3_object_version = aws_s3_object.notify_slack_code.version_id
  function_name     = "NotifySlack"
  role              = aws_iam_role.notify_slack_lambda.arn
  handler           = "notify_slack.handler"

  source_code_hash = data.archive_file.notify_slack_code.output_base64sha256
  runtime          = "nodejs18.x"
  timeout          = 300

  environment {
    variables = {
      ENVIRONMENT      = title(var.env)
      SLACK_WEBHOOK    = var.slack_webhook
      OPSGENIE_API_KEY = var.opsgenie_api_key
    }
  }

  tracing_config {
    mode = "PassThrough"
  }
}

#
# Allow SNS to invoke Lambda function
#
resource "aws_lambda_permission" "notify_slack_critical" {
  statement_id  = "AllowExecutionFromSNSCriticalAlert"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify_slack.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_alert_critical_arn
}

resource "aws_lambda_permission" "notify_slack_warning" {
  statement_id  = "AllowExecutionFromSNSWarningAlert"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify_slack.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_alert_warning_arn
}

resource "aws_lambda_permission" "notify_slack_ok" {
  statement_id  = "AllowExecutionFromSNSOkAlert"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify_slack.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_alert_ok_arn
}

resource "aws_lambda_permission" "notify_slack_warning_us_east" {
  statement_id  = "AllowExecutionFromSNSWarningAlertUSEast"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify_slack.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_alert_warning_us_east_arn
}

resource "aws_lambda_permission" "notify_slack_ok_us_east" {
  statement_id  = "AllowExecutionFromSNSOkAlertUSEast"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify_slack.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_alert_ok_us_east_arn
}

#
# IAM: Notify Slack Lambda
#
resource "aws_iam_role" "notify_slack_lambda" {
  name               = "NotifySlackLambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_policy.json


}

data "aws_iam_policy_document" "lambda_assume_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "notify_slack_lambda_basic_access" {
  role       = aws_iam_role.notify_slack_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "notify_slack" {
  name              = "/aws/lambda/${aws_lambda_function.notify_slack.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}