
# Vault data integrity check
#

data "archive_file" "vault_integrity_code" {
  type        = "zip"
  source_dir  = "./code/vault_integrity/dist/"
  output_path = "/tmp/vault_integrity_code.zip"
}

resource "aws_s3_object" "vault_integrity_code" {

  bucket      = var.lambda_code_id
  key         = "vault_integrity_code"
  source      = data.archive_file.vault_integrity_code.output_path
  source_hash = data.archive_file.vault_integrity_code.output_base64sha256
}

resource "aws_lambda_function" "vault_integrity" {
  s3_bucket         = var.env != "local" ? aws_signer_signing_job.vault_integrity[0].signed_object[0].s3[0].bucket : aws_s3_object.vault_integrity_code.bucket
  s3_key            = var.env != "local" ? aws_signer_signing_job.vault_integrity[0].signed_object[0].s3[0].key : aws_s3_object.vault_integrity_code.key
  s3_object_version = var.env != "local" ? null : aws_s3_object.vault_integrity_code.version_id
  function_name     = "Vault_Data_Integrity_Check"
  role              = aws_iam_role.lambda.arn
  handler           = "vault_data_integrity_check.handler"
  timeout           = 60

  source_code_hash        = data.archive_file.vault_integrity_code.output_base64sha256
  code_signing_config_arn = var.env != "local" ? aws_lambda_code_signing_config.lambda_code_signing_config[0].arn : null

  runtime = "nodejs18.x"

  environment {
    variables = {
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
  retention_in_days = 90
}

# Signer configuration


resource "aws_signer_signing_job" "vault_integrity" {
  count        = var.localstack_hosted ? 0 : 1
  profile_name = aws_signer_signing_profile.lambda_signing_profile[0].name

  source {
    s3 {
      bucket  = aws_s3_object.vault_integrity_code.bucket
      key     = aws_s3_object.vault_integrity_code.key
      version = aws_s3_object.vault_integrity_code.version_id
    }
  }

  destination {
    s3 {
      bucket = aws_s3_object.vault_integrity_code.bucket
      prefix = "signed/"
    }
  }

  ignore_signing_job_failure = true
} 