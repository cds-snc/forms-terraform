#
# Load testing
#

resource "aws_lambda_function" "load_testing" {
  image_uri     = "${var.ecr_repository_url_load_testing_lambda}:latest"
  function_name = "load-testing"
  role          = aws_iam_role.load_test_lambda.arn
  timeout       = 900
  memory_size   = 1024
  package_type  = "Image"
  description   = "A function that runs a locust load test"

  lifecycle {
    ignore_changes = [image_uri]
  }

  tracing_config {
    mode = "PassThrough"
  }
}

#
# IAM: Load testing
#

resource "aws_iam_role" "load_test_lambda" {
  name               = "LoadTestLambda"
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

resource "aws_iam_policy" "load_test_lambda" {
  name        = "LoadTestLambda"
  description = "Allow access to resources needed by the load testing Lambda function"
  policy      = data.aws_iam_policy_document.load_test_lambda.json
}

resource "aws_iam_role_policy_attachment" "load_test_lambda" {
  role       = aws_iam_role.load_test_lambda.name
  policy_arn = aws_iam_policy.load_test_lambda.arn
}

resource "aws_iam_role_policy_attachment" "load_test_lambda_basic_access" {
  role       = aws_iam_role.load_test_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "load_test_lambda" {
  statement {
    sid    = "GetSSMParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
    ]
    resources = [
      aws_ssm_parameter.load_testing_zitadel_app_private_key.arn,
    ]
  }

  statement {
    sid    = "InvokeSubmissionLambda"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
    ]
    resources = [
      "arn:aws:lambda:${var.region}:${var.account_id}:function:${var.lambda_submission_function_name}",
    ]
  }
}
