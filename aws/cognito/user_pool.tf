resource "aws_cognito_user_pool" "forms" {
  name                     = "forms_user_pool"
  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]
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
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
  verification_message_template {
    default_email_option  = "CONFIRM_WITH_LINK"
    email_message_by_link = "Please confirm your email / S.V.P confirmer votre email {##Click Here##}"
    email_subject_by_link = "Please confirm your email for GC Forms / S.V.P confirmer votre email pour GC Formulaire  "
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
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
  callback_urls                        = ["https://${var.domain}/api/auth/callback/cognito", "https://localhost:3000/api/auth/callback/cognito"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  supported_identity_providers         = ["COGNITO"]
  explicit_auth_flows                  = ["ALLOW_ADMIN_USER_PASSWORD_AUTH"]
  generate_secret                      = true
}

resource "aws_cognito_user_pool_domain" "forms" {
  domain       = "forms"
  user_pool_id = aws_cognito_user_pool.forms.id
}