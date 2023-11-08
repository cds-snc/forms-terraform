output "notify_api_key_secret" {
    description = "ARN of notify_api_key secret"
    value = aws_secretsmanager_secret_version.notify_api_key.arn
}

output "freshdesk_api_key_secret" {
    description = "ARNH of freshdesk_api_key secret"
    value = aws_secretsmanager_secret.freshdesk_api_key.arn
}

output "token_secret" {
    description = "ARN of tokensecret"
    value = aws_secretsmanager_secret.token_secret.arn
}

output "recaptcha_secret" {
    description = "ARN of recaptcha_secret"
    value = aws_secretsmanager_secret.recaptcha_secret.arn
}

output "notify_callback_bearer_token_secret" {
    description = "ARN of notify_callback_bearer_token_secret"
    value = aws_secretsmanager_secret.notify_callback_bearer_token.arn
}