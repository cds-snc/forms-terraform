resource "aws_iam_role" "lambda" {
  name               = "iam_for_vpn_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "vpn_lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging.json
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
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_policy" "lambda_vpc" {
  name        = "vpn_lambda_vpc"
  path        = "/"
  description = "IAM policy for allowing lambda to manage VPC"
  policy      = data.aws_iam_policy_document.lambda_vpc.json
}

data "aws_iam_policy_document" "lambda_vpc" {
  # checkov:skip=CKV2_AWS_111: This is a development environment, no need to restrict the lambda permissions
  # checkov:skip=CKV2_AWS_356: This is a development environment, no need to restrict the lambda permissions
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeClientVpnTargetNetworks",
      "ec2:DisassociateClientVpnTargetNetwork",
      "ec2:DescribeClientVpnConnections",
      "ec2:DescribeClientVpnEndpoints"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_vpc.arn
}

data "archive_file" "vpn_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/code/dist"
  output_path = "${path.module}/lambda/vpn_lambda.zip"
}

resource "aws_lambda_function" "vpn_lambda" {
  filename      = data.archive_file.vpn_lambda.output_path
  function_name = "vpn-scheduler"
  role          = aws_iam_role.lambda.arn
  handler       = "main.handler"

  source_code_hash = data.archive_file.vpn_lambda.output_base64sha256

  runtime = "nodejs18.x"

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_permission" "vpn-scheduler" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.vpn_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.vpn_lambda_trigger.arn
}