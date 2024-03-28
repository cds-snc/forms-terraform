#
# Archive form templates
#

resource "aws_lambda_function" "form_archiver" {
  function_name = "form-archiver"
  image_uri     = "${var.ecr_repository_url_form_archiver_lambda}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 300

  environment {
    variables = {
      REGION    = var.region
      DB_ARN    = var.rds_cluster_arn
      DB_SECRET = var.database_secret_arn
      DB_NAME   = var.rds_db_name
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