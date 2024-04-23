
#
# Archive form responses
#

resource "aws_lambda_function" "response_archiver" {
  function_name = "response-archiver"
  image_uri     = "${var.ecr_repository_url_response_archiver_lambda}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 300

  lifecycle {
    ignore_changes = [image_uri]
  }

  environment {
    variables = {
      REGION                       = var.region
      DYNAMODB_VAULT_TABLE_NAME    = var.dynamodb_vault_table_name
      ARCHIVING_S3_BUCKET          = var.archive_storage_id
      VAULT_FILE_STORAGE_S3_BUCKET = var.vault_file_storage_id
      LOCALSTACK                   = var.localstack_hosted
    }
  }

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_run_archive_form_responses_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.response_archiver.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.response_archiver_lambda_trigger.arn
}

resource "aws_cloudwatch_log_group" "response_archiver" {
  name              = "/aws/lambda/${aws_lambda_function.response_archiver.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}