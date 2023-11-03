resource "aws_signer_signing_profile" "lambda_signing_profile" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name_prefix = "lambda_signing_profile_"
}

resource "aws_lambda_code_signing_config" "lambda_code_signing_config" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.lambda_signing_profile.version_arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
}

resource "aws_signer_signing_job" "vault_data_integrity_check_lambda_signing_job" {
  profile_name = aws_signer_signing_profile.lambda_signing_profile.name

  source {
    s3 {
      bucket  = aws_s3_bucket.code_signed_lambda_storage.id
      key     = aws_s3_bucket_object.vault_data_integrity_check_main.id
      version = aws_s3_bucket_object.vault_data_integrity_check_main.version_id
    }
  }

  destination {
    s3 {
      bucket = aws_s3_bucket.code_signed_lambda_storage.id
      prefix = "signed/"
    }
  }

  ignore_signing_job_failure = true

  depends_on = [
    aws_s3_bucket_object.vault_data_integrity_check_main
  ]
}