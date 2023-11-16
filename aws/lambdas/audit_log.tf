
#
# Audit Log Processing
#
data "archive_file" "audit_logs_code" {
  type        = "zip"
  source_dir  = "./code/audit_logs/"
  output_path = "/tmp/audit_logs_code.zip"
}

resource "aws_s3_bucket_object" "audit_logs_code" {
  bucket      = var.lambda_code_id
  key         = "audit_logs_code"
  source      = data.archive_file.audit_logs_code.output_path
  source_hash = data.archive_file.audit_logs_code.output_base64sha256
}

resource "aws_lambda_function" "audit_logs" {
  s3_bucket     = aws_s3_bucket_object.audit_logs_code.bucket
  s3_key        = aws_s3_bucket_object.audit_logs_code.key
  function_name = "Audit_Logs"
  role          = aws_iam_role.lambda.arn
  handler       = "audit_logs.handler"
  timeout       = 60

  source_code_hash = data.archive_file.audit_logs_code.output_base64sha256

  runtime = "nodejs18.x"

  environment {
    variables = {
      REGION     = var.region
      LOCALSTACK = var.localstack_hosted
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

resource "aws_lambda_event_source_mapping" "audit_logs" {
  event_source_arn                   = var.sqs_audit_log_queue_arn
  function_name                      = aws_lambda_function.audit_logs.arn
  function_response_types            = ["ReportBatchItemFailures"]
  batch_size                         = 10
  maximum_batching_window_in_seconds = 30
  enabled                            = true
}

resource "aws_cloudwatch_log_group" "audit_logs" {
  name              = "/aws/lambda/${aws_lambda_function.audit_logs.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 90
}
