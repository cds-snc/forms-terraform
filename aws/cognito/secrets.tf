resource "aws_secretsmanager_secret" "cognito_notify_api_key" {
  name                    = "cognito_notify_api_key"
  recovery_window_in_days = 0

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_secretsmanager_secret_version" "cognito_notify_api_key" {
  secret_id     = aws_secretsmanager_secret.cognito_notify_api_key.id
  secret_string = var.cognito_notify_api_key
}