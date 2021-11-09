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

resource "aws_iam_policy" "notify_slack_lambda_logging" {
  name        = "notify_slack_lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_iam_role_policy_attachment" "notify_slack_lambda_logging" {
  role       = aws_iam_role.notify_slack_lambda.name
  policy_arn = aws_iam_policy.notify_slack_lambda_logging.arn
}

data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:${var.region}:${var.account_id}:*"
    ]
  }
}
