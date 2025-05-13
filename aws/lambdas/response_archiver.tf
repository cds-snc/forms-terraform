
#
# Archive form responses
#

resource "aws_lambda_function" "response_archiver" {
  function_name = "response-archiver"
  architectures = ["arm64"]
  image_uri     = "${var.ecr_repository_lambda_urls["response-archiver-lambda"]}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 900

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
      REGION                       = var.region
      DYNAMODB_VAULT_TABLE_NAME    = var.dynamodb_vault_table_name
      ARCHIVING_S3_BUCKET          = var.archive_storage_id
      VAULT_FILE_STORAGE_S3_BUCKET = var.vault_file_storage_id
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/Response_Archiver"
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

/*
 * When implementing containerized Lambda we had to rename some of the functions.
 * In order to keep existing log groups we decided to hardcode the group name and make the Lambda write to that legacy group.
 */

resource "aws_cloudwatch_log_group" "response_archiver" {
  name              = "/aws/lambda/Response_Archiver"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}
