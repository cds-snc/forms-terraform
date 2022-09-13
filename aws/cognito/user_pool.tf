resource "aws_cognito_user_pool" "forms" {
  name = "forms_user_pool"
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
  username_configuration {
    case_sensitive = true
  }
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
  admin_create_user_config {
    allow_admin_create_user_only = true
    invite_message_template {
      email_message = "Welcome!  Please log in using the following credentials:/n  Username: {username}/n  Password: {####}"
      email_subject = "Welcome to GCForms"
      sms_message   = "Welcome!  Please log in using the following credentials:/n  Username: {username}/n  Password: {####}"
    }
  }

}



resource "aws_cognito_user_pool_client" "forms" {
  name = "forms_client"

  user_pool_id                         = aws_cognito_user_pool.forms.id
  callback_urls                        = ["https://${var.domain}/api/auth/callback/cognito"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  supported_identity_providers         = ["COGNITO"]
  generate_secret                      = true
}