#
# Nagware
#

resource "aws_lambda_function" "nagware" {
  function_name = "nagware"
  image_uri     = "${var.ecr_repository_url_nagware_lambda}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 900

  vpc_config {
    security_group_ids = [var.lambda_nagware_security_group_id]
    subnet_ids         = var.private_subnet_ids
  }

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
      REDIS_URL                 = "redis://${var.redis_url}:${var.redis_port}"
      TEMPLATE_ID               = var.gc_template_id
      LOCALSTACK                = var.localstack_hosted
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/Nagware"
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

/*
 * When implementing containerized Lambda we had to rename some of the functions.
 * In order to keep existing log groups we decided to hardcode the group name and make the Lambda write to that legacy group.
 */

resource "aws_cloudwatch_log_group" "nagware" {
  name              = "/aws/lambda/Nagware"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}
