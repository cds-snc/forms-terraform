#
# Form File Upload API processing
#


resource "aws_lambda_function" "file_upload" {
  function_name = "file-upload-processor"
  image_uri     = "${var.ecr_repository_lambda_urls["file-upload-processor-lambda"]}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 300
  memory_size   = 256

  # Only allow a single instance to run at a time
  reserved_concurrent_executions = 1

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
      ENVIRONMENT = local.env
      REGION      = var.region
      SQS_URL     = var.sqs_reliability_queue_id
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/file-upload-processor"
  }

  tracing_config {
    mode = "Active"
  }
}


resource "aws_lambda_event_source_mapping" "file_upload" {
  event_source_arn                   = var.sqs_file_upload_queue_arn
  function_name                      = aws_lambda_function.file_upload.arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 30
  enabled                            = true

}

resource "aws_cloudwatch_log_group" "file_upload" {
  name              = "/aws/lambda/file-upload-processor"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}
