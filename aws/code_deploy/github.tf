resource "aws_codestarconnections_connection" "github" {
  name          = "GitHub-GCForms"
  provider_type = "GitHub"
}

resource "aws_codebuild_source_credential" "github" {
  auth_type   = "CODECONNECTIONS"
  server_type = "GITHUB"
  token       = aws_codestarconnections_connection.github.arn
}

resource "aws_codebuild_webhook" "github" {
  project_name    = aws_codebuild_project.github_runner.name
  build_type      = "BUILD"
  manual_creation = true
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "WORKFLOW_JOB_QUEUED"
    }
  }
}

resource "aws_codebuild_project" "github_runner" {
  name          = title("${var.env}-Github-Runner")
  description   = "Github Runner for GCForms"
  build_timeout = 5
  service_role  = aws_iam_role.code_build_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type = "NO_CACHE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "DATABASE_URL"
      type  = "SECRETS_MANAGER"
      value = var.database_url_secret_arn
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "Cloud-Build"
      stream_name = "log-stream"
    }

  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/cds-snc/platform-forms-client.git"
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }
  }

  source_version = "main"

  vpc_config {
    vpc_id = var.vpc_id

    subnets = var.private_subnet_ids

    security_group_ids = [
      var.code_build_security_group_id
    ]
  }
}