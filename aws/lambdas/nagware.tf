#
# Nagware
#

resource "aws_lambda_function" "nagware" {
  function_name = "nagware"
  image_uri     = "${var.ecr_repository_url_nagware_lambda}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 300

  lifecycle {
    ignore_changes = [image_uri]
  }

  environment {
    variables = {
      ENVIRONMENT               = var.env
      REGION                    = var.region
      DOMAIN                    = var.domains[0]
      DYNAMODB_VAULT_TABLE_NAME = var.dynamodb_vault_table_name
      DB_ARN                    = var.rds_cluster_arn
      DB_SECRET                 = var.database_secret_arn
      DB_NAME                   = var.rds_db_name
      NOTIFY_API_KEY            = var.notify_api_key_secret_arn
      TEMPLATE_ID               = var.gc_template_id
      LOCALSTACK                = var.localstack_hosted
    }
  }

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_run_nagware_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nagware.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.nagware_lambda_trigger.arn
}

resource "aws_cloudwatch_log_group" "nagware" {
  name              = "/aws/lambda/${aws_lambda_function.nagware.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}