
resource "aws_signer_signing_profile" "lambda_signing_profile" {
  count       = var.env != "local" ? 1 : 0
  platform_id = "AWSLambda-SHA384-ECDSA"
  name_prefix = "lambda_signing_profile_"
}

resource "aws_lambda_code_signing_config" "lambda_code_signing_config" {
  count = var.env != "local" ? 1 : 0
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.lambda_signing_profile[0].version_arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
}