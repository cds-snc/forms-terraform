#
# VPC Flow Logs:
# Capture network traffic over the VPC
#
resource "aws_flow_log" "vpc_flow_logs" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.forms.id

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "vpc_flow_logs"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 30

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_iam_role" "vpc_flow_logs" {
  name               = "vpc_flow_logs"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_logs_role_policy.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

data "aws_iam_policy_document" "vpc_flow_logs_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name   = "vpc_flow_logs"
  role   = aws_iam_role.vpc_flow_logs.id
  policy = data.aws_iam_policy_document.vpc_flow_logs_policy.json
}

data "aws_iam_policy_document" "vpc_flow_logs_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]

    resources = [
      aws_cloudwatch_log_group.vpc_flow_logs.arn,
      "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:log-stream:*"
    ]
  }
}
