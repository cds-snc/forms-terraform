output "notify_api_key_secret_arn" {
  description = "ARN of notify_api_key secret"
  value       = aws_secretsmanager_secret_version.notify_api_key.arn
}

output "freshdesk_api_key_secret_arn" {
  description = "ARN of freshdesk_api_key secret"
  value       = aws_secretsmanager_secret.freshdesk_api_key.arn
}

output "sentry_api_key_secret_arn" {
  description = "ARN of sentry_api_key secret"
  value       = aws_secretsmanager_secret.sentry_api_key.arn
}

output "token_secret_arn" {
  description = "ARN of tokensecret"
  value       = aws_secretsmanager_secret.token_secret.arn
}

output "recaptcha_secret_arn" {
  description = "ARN of recaptcha_secret"
  value       = aws_secretsmanager_secret.recaptcha_secret.arn
}

output "notify_callback_bearer_token_secret_arn" {
  description = "ARN of notify_callback_bearer_token_secret"
  value       = aws_secretsmanager_secret.notify_callback_bearer_token.arn
}

output "zitadel_administration_key_secret_arn" {
  description = "ARN of zitadel_administration_key secret"
  value       = aws_secretsmanager_secret_version.zitadel_administration_key.arn
}

output "zitadel_application_key_secret_arn" {
  description = "ARN of zitadel_application_key secret"
  value       = aws_secretsmanager_secret_version.zitadel_application_key.arn
}

output "hcaptcha_site_verify_key_secret_arn" {
  description = "The hCaptcha site verify key secret used for forms"
  value       = aws_secretsmanager_secret_version.hcaptcha_site_verify_key.arn
}
