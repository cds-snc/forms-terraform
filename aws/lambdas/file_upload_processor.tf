#
# Form File Upload API processing
#

/*
 * For the submission Lambda, when working on https://github.com/cds-snc/forms-terraform/pull/626, we decided to not rename the function name
 * to avoid any service disruption when releasing to Production. This is due to the web application directly calling the Submission (with a capital S) Lambda.
 * All the others Lambda functions have lowercase names.
 */

resource "aws_lambda_function" "file_upload" {
  function_name = "file-upload-processor"
  image_uri     = "${var.ecr_repository_lambda_urls["file-upload-processor-lambda"]}:latest"
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

resource "aws_s3_bucket_notification" "file_upload" {
  bucket = var.reliability_file_storage_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.file_upload.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.file_upload]
}

resource "aws_lambda_permission" "file_upload" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.file_upload.arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.reliability_file_storage_arn
}


resource "aws_cloudwatch_log_group" "file_upload" {
  name              = "/aws/lambda/file-upload-processor"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}
