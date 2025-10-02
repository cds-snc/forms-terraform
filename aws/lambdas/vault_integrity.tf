#
# Vault data integrity check
#

resource "aws_lambda_function" "vault_integrity" {
  function_name = "vault-integrity"
  image_uri     = "${var.ecr_repository_lambda_urls["vault-integrity-lambda"]}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 60
  memory_size   = 256

  // This lambda does not need to be connected to the VPC
  // It is a read-only operation that is invoked securely through the Lambda Private Link Endpoint

  lifecycle {
    ignore_changes = [image_uri]
  }

  logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/Vault_Data_Integrity_Check"
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_event_source_mapping" "vault_updated_item_stream" {
  event_source_arn                   = var.dynamodb_vault_stream_arn
  function_name                      = aws_lambda_function.vault_integrity.arn
  starting_position                  = "LATEST"
  maximum_batching_window_in_seconds = 60 # Either 1 minute of waiting or 100 events are available before the lambda is triggered
  maximum_retry_attempts             = 3

  filter_criteria {
    filter {
      pattern = jsonencode({
        eventName : ["INSERT", "MODIFY"]
      })
    }
  }
}

/*
 * When implementing containerized Lambda we had to rename some of the functions.
 * In order to keep existing log groups we decided to hardcode the group name and make the Lambda write to that legacy group.
 */

resource "aws_cloudwatch_log_group" "vault_integrity" {
  name              = "/aws/lambda/Vault_Data_Integrity_Check"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}
