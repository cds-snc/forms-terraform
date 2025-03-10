#
# ECS and Lambda app secrets
#
resource "aws_secretsmanager_secret" "notify_api_key" {
  # checkov:skip=CKV2_AWS_57: Automatic secret rotation not required
  name                    = "notify_api_key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "notify_api_key" {
  secret_id     = aws_secretsmanager_secret.notify_api_key.id
  secret_string = var.notify_api_key
}

resource "aws_secretsmanager_secret" "freshdesk_api_key" {
  # checkov:skip=CKV2_AWS_57: Automatic secret rotation not required
  name                    = "freshdesk_api_key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "freshdesk_api_key" {
  secret_id     = aws_secretsmanager_secret.freshdesk_api_key.id
  secret_string = var.freshdesk_api_key
}

resource "aws_secretsmanager_secret" "sentry_api_key" {
  # checkov:skip=CKV2_AWS_57: Automatic secret rotation not required
  name                    = "sentry_api_key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "sentry_api_key" {
  secret_id     = aws_secretsmanager_secret.sentry_api_key.id
  secret_string = var.sentry_api_key
}


resource "aws_secretsmanager_secret" "token_secret" {
  # checkov:skip=CKV2_AWS_57: Automatic secret rotation not required
  name                    = "token_secret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "token_secret" {
  secret_id     = aws_secretsmanager_secret.token_secret.id
  secret_string = var.ecs_secret_token
}

resource "aws_secretsmanager_secret" "recaptcha_secret" {
  # checkov:skip=CKV2_AWS_57: Automatic secret rotation not required
  name                    = "recaptcha_secret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "recaptcha_secret" {
  secret_id     = aws_secretsmanager_secret.recaptcha_secret.id
  secret_string = var.recaptcha_secret
}

resource "aws_secretsmanager_secret" "notify_callback_bearer_token" {
  # checkov:skip=CKV2_AWS_57: Automatic secret rotation not required
  name                    = "notify_callback_bearer_token"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "notify_callback_bearer_token" {
  secret_id     = aws_secretsmanager_secret.notify_callback_bearer_token.id
  secret_string = var.notify_callback_bearer_token
}

resource "aws_secretsmanager_secret" "zitadel_administration_key" {
  # checkov:skip=CKV2_AWS_57: Automatic secret rotation not required
  name                    = "zitadel_administration_key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "zitadel_administration_key" {
  secret_id     = aws_secretsmanager_secret.zitadel_administration_key.id
  secret_string = var.zitadel_administration_key
}

resource "aws_secretsmanager_secret" "zitadel_application_key" {
  # checkov:skip=CKV2_AWS_57: Automatic secret rotation not required
  name                    = "zitadel_application_key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "zitadel_application_key" {
  secret_id     = aws_secretsmanager_secret.zitadel_application_key.id
  secret_string = var.zitadel_application_key
}

resource "aws_secretsmanager_secret_version" "hcaptcha_site_verify_key" {
  secret_id     = aws_secretsmanager_secret.hcaptcha_site_verify_key.id
  secret_string = var.hcaptcha_site_verify_key
}

resource "aws_secretsmanager_secret" "hcaptcha_site_verify_key" {
  # checkov:skip=CKV2_AWS_57: Automatic secret rotation not required
  name                    = "hcaptcha_site_verify_key"
  recovery_window_in_days = 0
}
