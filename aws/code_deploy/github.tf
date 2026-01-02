resource "aws_codestarconnections_connection" "github" {
  name          = "GitHub-GCForms"
  provider_type = "GitHub"
}

resource "aws_codebuild_source_credential" "github" {
  auth_type   = "CODECONNECTIONS"
  server_type = "GITHUB"
  token       = aws_codestarconnections_connection.github.arn
}
