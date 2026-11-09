resource "aws_lambda_function" "overdue_responses_janitor" {
  function_name = "overdue-responses-janitor"
  image_uri     = "${var.ecr_repository_lambda_urls["overdue-responses-janitor-lambda"]}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 900
  memory_size   = 512
  architectures = ["arm64"]

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
      REGION                    = var.region
      DYNAMODB_VAULT_TABLE_NAME = var.dynamodb_vault_table_name
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/overdue-responses-janitor"
  }

  tracing_config {
    mode = "Active"
  }
}

/*
 * When implementing containerized Lambda we had to rename some of the functions.
 * In order to keep existing log groups we decided to hardcode the group name and make the Lambda write to that legacy group.
 */

resource "aws_cloudwatch_log_group" "overdue_responses_janitor" {
  name              = "/aws/lambda/overdue-responses-janitor"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731

  tags = var.core_tags
}
