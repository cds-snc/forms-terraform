resource "aws_lambda_function" "reliability" {
  function_name = "reliability"
  image_uri     = "${var.ecr_repository_lambda_urls["reliability-lambda"]}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 300

  dynamic "vpc_config" {
    for_each = local.vpc_config
    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnet_ids         = vpc_config.value.subnets
    }
  }

  lifecycle {
    ignore_changes = [image_uri]
  }

  environment {
    variables = {
      ENVIRONMENT    = var.env
      REGION         = var.region
      NOTIFY_API_KEY = var.notify_api_key_secret_arn
      TEMPLATE_ID    = var.gc_template_id
      DB_URL         = var.database_url_secret_arn
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/Reliability"
  }

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_event_source_mapping" "reliability" {
  event_source_arn = var.sqs_reliability_queue_arn
  function_name    = aws_lambda_function.reliability.arn
  batch_size       = 1
  enabled          = true
}

resource "aws_lambda_event_source_mapping" "reprocess_submission" {
  event_source_arn = var.sqs_reprocess_submission_queue_arn
  function_name    = aws_lambda_function.reliability.arn
  batch_size       = 1
  enabled          = true
}

/*
 * When implementing containerized Lambda we had to rename some of the functions.
 * In order to keep existing log groups we decided to hardcode the group name and make the Lambda write to that legacy group.
 */

resource "aws_cloudwatch_log_group" "reliability" {
  name              = "/aws/lambda/Reliability"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}
