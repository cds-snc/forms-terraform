resource "aws_secretsmanager_secret" "this" {
  # checkov:skip=CKV2_AWS_57: Automatic secret rotation not required
  name                    = "github-webhook-${var.app_name}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.webhook_secret
}