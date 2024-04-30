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
  s3_bucket         = aws_s3_object.submission_code.bucket
  s3_key            = aws_s3_object.submission_code.key
  s3_object_version = aws_s3_object.submission_code.version_id
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



}

# Allow ECS to invoke Submission Lambda

resource "aws_lambda_permission" "submission" {
  statement_id  = "AllowInvokeECS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.submission.function_name
  principal     = var.ecs_iam_role_arn
}

/*
 * This is a temporary change to allow the web application to call the legacy submission Lambda function name (see https://github.com/cds-snc/platform-forms-client/commit/48919e38b00c4ce591009f7dd076e3f8b4bbf5c3)
 * It can be removed once we have released https://github.com/cds-snc/forms-terraform/pull/626 in Production.
 */

resource "aws_lambda_permission" "submission_option_2" {
  statement_id  = "AllowInvokeECS"
  action        = "lambda:InvokeFunction"
  function_name = "submission" // This will be changed to Submission in the Lambda containerization pull request
  principal     = var.ecs_iam_role_arn
}

resource "aws_cloudwatch_log_group" "submission" {
  name              = "/aws/lambda/${aws_lambda_function.submission.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}
