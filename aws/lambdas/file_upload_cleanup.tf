#
# File Upload S3 Clean up
#

resource "aws_lambda_function" "file_upload_cleanup" {
  function_name = "file-upload-cleanup"
  # image_uri     = "${var.ecr_repository_lambda_urls["file-upload-cleanup-lambda"]}:latest"
  image_uri    = "730335263169.dkr.ecr.ca-central-1.amazonaws.com/file-upload-cleanup-lambda:latest"
  package_type = "Image"
  role         = aws_iam_role.lambda.arn
  timeout      = 300

  // This lambda does not need to be connected to the VPC
  // It is a read-only operation that is invoked securely through the Lambda Private Link Endpoint

  lifecycle {
    ignore_changes = [image_uri]
  }

  environment {
    variables = {
      ENVIRONMENT              = local.env
      REGION                   = var.region
      RELIABILITY_FILE_STORAGE = var.reliability_file_storage_id
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/file-upload-cleanup"
  }

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_run_file_upload_cleanup_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.file_upload_cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.file_upload_cleanup_trigger.arn
}



/*
 * When implementing containerized Lambda we had to rename some of the functions.
 * In order to keep existing log groups we decided to hardcode the group name and make the Lambda write to that legacy group.
 */

resource "aws_cloudwatch_log_group" "file_upload_cleanup" {
  name              = "/aws/lambda/file-upload-cleanup"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}
