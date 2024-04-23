#
# Vault data integrity check
#

resource "aws_lambda_function" "vault_integrity" {
  function_name = "vault-integrity"
  image_uri     = "${var.ecr_repository_url_vault_integrity_lambda}:latest"
  package_type  = "Image"
  role          = aws_iam_role.lambda.arn
  timeout       = 60

  lifecycle {
    ignore_changes = [image_uri]
  }

  tracing_config {
    mode = "PassThrough"
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

resource "aws_cloudwatch_log_group" "vault_integrity" {
  name              = "/aws/lambda/${aws_lambda_function.vault_integrity.function_name}"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}