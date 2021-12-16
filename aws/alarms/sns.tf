#
# SNS topic subscriptions
#
resource "aws_sns_topic_subscription" "topic_critical" {
  topic_arn = var.sns_topic_alert_critical_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notify_slack_sns.arn
}

resource "aws_sns_topic_subscription" "topic_warning" {
  topic_arn = var.sns_topic_alert_warning_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notify_slack_sns.arn
}

resource "aws_sns_topic_subscription" "topic_ok" {
  topic_arn = var.sns_topic_alert_ok_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notify_slack_sns.arn
}

resource "aws_sns_topic_subscription" "topic_warning_us_east" {
  provider = aws.us-east-1

  topic_arn = var.sns_topic_alert_warning_us_east_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notify_slack_sns.arn
}

resource "aws_sns_topic_subscription" "topic_ok_us_east" {
  provider = aws.us-east-1

  topic_arn = var.sns_topic_alert_ok_us_east_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notify_slack_sns.arn
}

#
# CloudWatch Policy
#
resource "aws_sns_topic_policy" "cloudwatch_events_critical_sns" {
  arn    = var.sns_topic_alert_critical_arn
  policy = data.aws_iam_policy_document.cloudwatch_events_sns_topic_policy.json
}

resource "aws_sns_topic_policy" "cloudwatch_events_warning_sns" {
  arn    = var.sns_topic_alert_warning_arn
  policy = data.aws_iam_policy_document.cloudwatch_events_sns_topic_policy.json
}

resource "aws_sns_topic_policy" "cloudwatch_events_ok_sns" {
  arn    = var.sns_topic_alert_ok_arn
  policy = data.aws_iam_policy_document.cloudwatch_events_sns_topic_policy.json
}

data "aws_iam_policy_document" "cloudwatch_events_sns_topic_policy" {
  statement {
    # checkov:skip=CKV_AWS_111: False-positive, `resources = ["*"]` refers to the SNS topic the policy applies to 
    sid    = "SNS_Default_Policy"
    effect = "Allow"
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        var.account_id,
      ]
    }

    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    sid    = "SNS_Publish_statement"
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]

    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}