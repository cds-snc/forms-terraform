output "notify_api_key_secret_arn" {
  description = "ARN of notify_api_key secret"
  value       = aws_secretsmanager_secret_version.notify_api_key.arn
}

output "notify_api_key_secret_value" {
  description = "Value of notify_api_key secret"
  value       = aws_secretsmanager_secret_version.notify_api_key.secret_string
  sensitive   = true
}

output "freshdesk_api_key_secret_arn" {
  description = "ARN of freshdesk_api_key secret"
  value       = aws_secretsmanager_secret.freshdesk_api_key.arn
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