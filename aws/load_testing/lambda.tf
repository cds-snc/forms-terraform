resource "aws_lambda_function" "load_testing" {
  function_name = "load-testing"
  description   = "A function that runs a Locust load test"
  role          = aws_iam_role.load_test_lambda.arn

  runtime     = "python3.12"
  timeout     = 900
  memory_size = 1024

  filename         = data.archive_file.load_testing_lambda_package.output_path
  source_code_hash = data.archive_file.load_testing_lambda_package.output_base64sha256
  handler          = "main.handler"

  layers = [
    aws_lambda_layer_version.load_testing_lambda_package_dependencies.arn
  ]

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_layer_version" "load_testing_lambda_package_dependencies" {
  layer_name = "load-testing-lambda-package-dependencies"

  s3_bucket = aws_s3_object.load_testing_lambda_package_dependencies.bucket
  s3_key    = aws_s3_object.load_testing_lambda_package_dependencies.key

  compatible_runtimes      = ["python3.12"]
  compatible_architectures = ["x86_64"]
}
