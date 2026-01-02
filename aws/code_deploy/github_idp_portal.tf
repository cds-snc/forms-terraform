
resource "aws_codebuild_webhook" "github_idp_portal" {
  project_name    = aws_codebuild_project.github_runner_idp_portal.name
  build_type      = "BUILD"
  manual_creation = true
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "WORKFLOW_JOB_QUEUED"
    }
  }
}

resource "aws_codebuild_project" "github_runner_idp_portal" {
  name          = title("${var.env}-IDP-Portal-Github-Runner")
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
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "Cloud-Build-IDP-Portal"
      stream_name = "log-stream"
    }

  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/cds-snc/forms-idp-user-portal.git"
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