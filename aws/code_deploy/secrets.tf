resource "aws_secretsmanager_secret" "github_webhook" {
  # checkov:skip=CKV2_AWS_57: Automatic secret rotation not required
  name                    = "github-webhook"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "github_webhook" {
  depends_on    = [aws_codebuild_webhook.github]
  secret_id     = aws_secretsmanager_secret.github_webhook.id
  secret_string = "{\"payload\": \"${aws_codebuild_webhook.github.payload_url}\",\"secret\": \"${aws_codebuild_webhook.github.secret}\",\"url\": \"${aws_codebuild_webhook.github.url}\"}"
}