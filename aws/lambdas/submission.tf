#
# Form Submission API processing
#

/*
 * For the submission Lambda, when working on https://github.com/cds-snc/forms-terraform/pull/626, we decided to not rename the function name
 * to avoid any service disruption when releasing to Production. This is due to the web application directly calling the Submission (with a capital S) Lambda.
 * All the others Lambda functions have lowercase names.
 */

resource "aws_lambda_function" "submission" {
  function_name = "Submission"
  image_uri     = "${var.ecr_repository_lambda_urls["submission-lambda"]}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 60

  lifecycle {
    ignore_changes = [image_uri]
  }

  dynamic "vpc_config" {
    for_each = local.vpc_config
    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnet_ids         = vpc_config.value.subnet_ids
    }
  }

  environment {
    variables = {
      REGION  = var.region
      SQS_URL = var.sqs_reliability_queue_id
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
  count         = var.env == "development" ? 0 : 1
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
