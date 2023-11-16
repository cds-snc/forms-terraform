
#
# Archive form responses
#
data "archive_file" "response_archiver_code" {
  type        = "zip"
  source_dir  = "./code/response_archiver/"
  output_path = "/tmp/response_archiver_code.zip"
}

resource "aws_s3_bucket_object" "response_archiver_code" {
  bucket      = var.lambda_code_id
  key         = "response_archiver_code"
  source      = data.archive_file.response_archiver_code.output_path
  source_hash = data.archive_file.response_archiver_code.output_base64sha256
  depends_on = [
    aws_s3_bucket.lambda_code,
    data.archive_file.response_archiver_code
  ]
}


resource "aws_lambda_function" "response_archiver" {
  s3_bucket     = aws_s3_bucket_object.response_archiver_code.bucket
  s3_key        = aws_s3_bucket_object.response_archiver_code.key
  function_name = "Response_Archiver"
  role          = aws_iam_role.lambda.arn
  handler       = "archiver.handler"

  source_code_hash = data.archive_file.response_archiver_code.output_base64sha256
  runtime          = "nodejs18.x"
  timeout          = 10

  environment {
    variables = {
      REGION                       = var.region
      DYNAMODB_VAULT_TABLE_NAME    = var.dynamodb_vault_table_name
      ARCHIVING_S3_BUCKET          = aws_s3_bucket.archive_storage.bucket
      VAULT_FILE_STORAGE_S3_BUCKET = aws_s3_bucket.vault_file_storage.bucket
      LOCALSTACK                   = var.localstack_hosted
    }
  }

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}


resource "aws_lambda_permission" "allow_cloudwatch_to_run_archive_form_responses_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.response_archiver.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron_3am_every_day.arn
}

resource "aws_cloudwatch_log_group" "archiver" {
  name              = "/aws/lambda/${aws_lambda_function.response_archiver.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 90
}
