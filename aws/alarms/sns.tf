#
# SNS topics
#
resource "aws_sns_topic" "alert_warning" {
  name              = "alert-warning"
  kms_master_key_id = var.kms_key_cloudwatch_arn

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_sns_topic" "alert_ok" {
  name              = "alert-ok"
  kms_master_key_id = var.kms_key_cloudwatch_arn
  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

#
# SNS topic subscriptions
#
resource "aws_sns_topic_subscription" "topic_warning" {
  topic_arn = aws_sns_topic.alert_warning.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notify_slack_sns.arn
}

resource "aws_sns_topic_subscription" "topic_ok" {
  topic_arn = aws_sns_topic.alert_ok.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.notify_slack_sns.arn
}

#
# CloudWatch Policy
#
resource "aws_sns_topic_policy" "cloudwatch_events_warning_sns" {
  arn    = aws_sns_topic.alert_warning.arn
  policy = data.aws_iam_policy_document.cloudwatch_events_sns_topic_policy.json
}

resource "aws_sns_topic_policy" "cloudwatch_events_ok_sns" {
  arn    = aws_sns_topic.alert_ok.arn
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
