#
# Nagware
#

resource "aws_lambda_function" "nagware" {
  function_name = "nagware"
  image_uri     = "${var.ecr_repository_lambda_urls["nagware-lambda"]}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 900
  memory_size   = 512

  // Even in development mode this lambda should be attached to the VPC in order to connecto the DB
  vpc_config {
    security_group_ids = [var.lambda_security_group_id]
    subnet_ids         = var.private_subnet_ids
  }

  lifecycle {
    ignore_changes = [image_uri]
  }

  environment {
    variables = {
      ENVIRONMENT               = local.env
      REGION                    = var.region
      DOMAIN                    = var.domains[0]
      DYNAMODB_VAULT_TABLE_NAME = var.dynamodb_vault_table_name
      DB_URL                    = var.database_url_secret_arn
      NOTIFY_API_KEY            = var.notify_api_key_secret_arn
      REDIS_URL                 = "redis://${var.redis_url}:${var.redis_port}"
      TEMPLATE_ID               = var.gc_template_id
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/Nagware"
  }

  tracing_config {
    mode = "Active"
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
