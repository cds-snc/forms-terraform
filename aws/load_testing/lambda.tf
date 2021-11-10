#
# Load testing
#
data "archive_file" "load_testing" {
  type        = "zip"
  source_dir  = "lambda/load_testing/"
  output_path = "/tmp/load_testing.zip"
}

resource "aws_lambda_function" "load_testing" {
  filename         = "/tmp/load_testing.zip"
  function_name    = "LoadTesting"
  role             = aws_iam_role.load_test_lambda.arn
  handler          = "lambda_locust.handler"
  timeout          = 300
  memory_size      = 200
  source_code_hash = data.archive_file.load_testing.output_base64sha256

  runtime     = "python3.8"
  description = "A function that runs a locust load test"

  environment {
    variables = {
      LOCUST_RUN_TIME    = "3m"
      LOCUST_LOCUSTFILE  = "locust_test_file.py"
      LOCUST_HOST        = "https://${var.domain}"
      LOCUST_HATCH_RATE  = "1"
      LOCUST_NUM_CLIENTS = "1"
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
# IAM: Load testing
#
resource "aws_iam_role" "load_test_lambda" {
  name               = "LoadTestLambda"
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

resource "aws_iam_role_policy_attachment" "load_test_lambda_basic_access" {
  role       = aws_iam_role.load_test_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
