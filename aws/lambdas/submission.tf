#
# Form Submission API processing
#
data "archive_file" "submission_code" {
  type        = "zip"
  source_dir  = "./code/submission/dist"
  output_path = "/tmp/submission_code.zip"
}

resource "aws_s3_object" "submission_code" {
  bucket      = var.lambda_code_id
  key         = "submission_code"
  source      = data.archive_file.submission_code.output_path
  source_hash = data.archive_file.submission_code.output_base64sha256
}

resource "aws_lambda_function" "submission" {
  s3_bucket         = aws_s3_bucket_object.submission_code.bucket
  s3_key            = aws_s3_bucket_object.submission_code.key
  s3_object_version = aws_s3_bucket_object.submission_code.version_id
  function_name     = "Submission"
  role              = aws_iam_role.lambda.arn
  handler           = "submission.handler"
  timeout           = 60

  source_code_hash = data.archive_file.submission_code.output_base64sha256

  runtime = "nodejs18.x"

  environment {
    variables = {
      REGION     = var.region
      SQS_URL    = var.sqs_reliability_queue_id
      LOCALSTACK = var.localstack_hosted
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

# Allow ECS to invoke Submission Lambda

resource "aws_lambda_permission" "submission" {
  statement_id  = "AllowInvokeECS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.submission.function_name
  principal     = var.ecs_iam_role_arn
}

resource "aws_cloudwatch_log_group" "submission" {
  name              = "/aws/lambda/${aws_lambda_function.submission.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 90
}
