#
# Cognito Secrets
#
resource "aws_secretsmanager_secret" "cognito_client_secret" {
  name                    = "cognito_client_secret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "cognito_client_secret" {
  secret_id     = aws_secretsmanager_secret.cognito_client_secret.id
  secret_string = aws_cognito_user_pool_client.forms.client_secret
}