resource "aws_lambda_function" "reliability" {
  function_name = "reliability"
  image_uri     = "${var.ecr_repository_lambda_urls["reliability-lambda"]}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 300
  memory_size   = 256

  // Even in development mode this lambda should be attached to the VPC in order to connecto the DB
  // In development mode the lambda cannot sent emails as there is no internet access
  vpc_config {
    security_group_ids = [var.lambda_security_group_id]
    subnet_ids         = var.private_subnet_ids
  }

  lifecycle {
    ignore_changes = [image_uri]
  }

  environment {
    variables = {
      ENVIRONMENT    = local.env
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
    mode = "Active"
  }
}

resource "aws_lambda_event_source_mapping" "reliability" {
  event_source_arn = var.sqs_reliability_queue_arn
  function_name    = aws_lambda_function.reliability.arn
  batch_size       = 1
  enabled          = true

  scaling_config {
    maximum_concurrency = 150
  }
}

resource "aws_lambda_event_source_mapping" "reprocess_submission" {
  event_source_arn = var.sqs_reliability_reprocessing_queue_arn
  function_name    = aws_lambda_function.reliability.arn
  batch_size       = 1
  enabled          = true

  scaling_config {
    maximum_concurrency = 150
  }
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
