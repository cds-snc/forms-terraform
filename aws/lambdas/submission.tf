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

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/Submission"
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
 * When implementing containerized Lambda we had to rename some of the functions.
 * In order to keep existing log groups we decided to hardcode the group name and make the Lambda write to that legacy group.
 */

resource "aws_cloudwatch_log_group" "submission" {
  name              = "/aws/lambda/Submission"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}
