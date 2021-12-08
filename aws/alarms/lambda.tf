#
# Lambda - Notify Slack
#
data "archive_file" "notify_slack" {
  type        = "zip"
  source_file = "lambda/notify_slack/notify_slack.js"
  output_path = "/tmp/notify_slack.zip"
}

#tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "notify_slack_sns" {
  filename      = "/tmp/notify_slack.zip"
  function_name = "NotifySlackSNS"
  role          = aws_iam_role.notify_slack_lambda.arn
  handler       = "notify_slack.handler"

  source_code_hash = data.archive_file.notify_slack.output_base64sha256

  runtime = "nodejs14.x"

  environment {
    variables = {
      ENVIRONMENT   = title(var.env)
      SLACK_WEBHOOK = var.slack_webhook
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

#
# Allow SNS to invoke Lambda function
#
resource "aws_lambda_permission" "notify_slack_warning" {
  statement_id  = "AllowExecutionFromSNSWarningAlert"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify_slack_sns.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alert_warning.arn
}

resource "aws_lambda_permission" "notify_slack_ok" {
  statement_id  = "AllowExecutionFromSNSOkAlert"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify_slack_sns.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alert_ok.arn
}

resource "aws_lambda_permission" "notify_slack_warning_us_east" {
  statement_id  = "AllowExecutionFromSNSWarningAlertUSEast"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify_slack_sns.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alert_warning_us_east.arn
}

resource "aws_lambda_permission" "notify_slack_ok_us_east" {
  statement_id  = "AllowExecutionFromSNSOkAlertUSEast"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notify_slack_sns.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alert_ok_us_east.arn
}

#
# IAM: Notify Slack Lambda
#
resource "aws_iam_role" "notify_slack_lambda" {
  name               = "NotifySlackLambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_policy.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
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
