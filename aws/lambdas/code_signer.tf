
resource "aws_signer_signing_profile" "lambda_signing_profile" {
  count       = var.localstack_hosted ? 0 : 1
  platform_id = "AWSLambda-SHA384-ECDSA"
  name_prefix = "lambda_signing_profile_"
}

resource "aws_lambda_code_signing_config" "lambda_code_signing_config" {
  count = var.localstack_hosted ? 0 : 1
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.lambda_signing_profile[0].version_arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
}