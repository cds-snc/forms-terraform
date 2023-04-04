resource "aws_cognito_user_pool" "forms" {
  name                     = "forms_user_pool"
  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]
  password_policy {
    temporary_password_validity_days = 7
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
  }
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  lambda_config {
    kms_key_id = aws_kms_key.cognito_encryption.arn
    custom_email_sender {
      lambda_arn     = aws_lambda_function.cognito_email_sender.arn
      lambda_version = "V1_0"
    }
  }

}

resource "aws_cognito_user_pool_client" "forms" {
  name = "forms_client"

  user_pool_id                         = aws_cognito_user_pool.forms.id
  callback_urls                        = ["https://${var.domain}/api/auth/callback/cognito", "https://localhost:3000/api/auth/callback/cognito"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  supported_identity_providers         = ["COGNITO"]
  explicit_auth_flows                  = ["ALLOW_ADMIN_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  generate_secret                      = false
}

resource "aws_cognito_user_pool_domain" "forms" {
  domain       = "forms"
  user_pool_id = aws_cognito_user_pool.forms.id
}

resource "aws_lambda_permission" "allow_cognito" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cognito_email_sender.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.forms.arn
}