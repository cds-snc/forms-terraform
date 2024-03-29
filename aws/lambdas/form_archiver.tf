#
# Archive form templates
#
data "archive_file" "form_archiver_code" {
  type        = "zip"
  source_dir  = "./code/form_archiver/dist"
  output_path = "/tmp/form_archiver_code.zip"
}

resource "aws_s3_object" "form_archiver_code" {
  bucket      = var.lambda_code_id
  key         = "form_archiver_code"
  source      = data.archive_file.form_archiver_code.output_path
  source_hash = data.archive_file.form_archiver_code.output_base64sha256
}

resource "aws_lambda_function" "form_archiver" {
  s3_bucket         = aws_s3_object.form_archiver_code.bucket
  s3_key            = aws_s3_object.form_archiver_code.key
  s3_object_version = aws_s3_object.form_archiver_code.version_id
  function_name     = "Archive_Form_Templates"
  role              = aws_iam_role.lambda.arn
  handler           = "form_archiver.handler"
  timeout           = 300

  source_code_hash = data.archive_file.form_archiver_code.output_base64sha256

  runtime = "nodejs18.x"

  environment {
    variables = {
      ENVIRONMENT = var.env
      REGION      = var.region
      DB_ARN      = var.rds_cluster_arn
      DB_SECRET   = var.database_secret_arn
      DB_NAME     = var.rds_db_name
      LOCALSTACK  = var.localstack_hosted
      PGHOST      = var.localstack_hosted ? "host.docker.internal" : null
      PGUSER      = var.localstack_hosted ? "postgres" : null
      PGDATABASE  = var.localstack_hosted ? "formsDB" : null
      PGPASSWORD  = var.localstack_hosted ? "chummy" : null
    }
  }

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_run_form_archiver_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.form_archiver.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.form_archiver_lambda_trigger.arn
}

resource "aws_cloudwatch_log_group" "archive_form_templates" {
  name              = "/aws/lambda/${aws_lambda_function.form_archiver.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}
