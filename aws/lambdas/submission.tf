#
# Form Submission API processing
#

resource "aws_lambda_function" "submission" {
  function_name = "submission"
  image_uri     = "${var.ecr_repository_url_submission_lambda}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 60

  lifecycle {
    ignore_changes = [image_uri]
  }

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

resource "aws_cloudwatch_log_group" "submission" {
  name              = "/aws/lambda/${aws_lambda_function.submission.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}