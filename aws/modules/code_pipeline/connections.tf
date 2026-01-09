resource "aws_codestarconnections_connection" "this" {
  name          = "${var.app_name}-GitHub"
  provider_type = "GitHub"
}

resource "aws_codepipeline_webhook" "this" {
  name            = "github-webhook-${var.app_name}"
  authentication  = "GITHUB_HMAC"
  target_action   = "Source"
  target_pipeline = aws_codepipeline.this.name

  authentication_configuration {
    secret_token = aws_secretsmanager_secret_version.this.arn
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}