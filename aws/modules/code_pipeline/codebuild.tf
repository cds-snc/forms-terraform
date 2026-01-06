
resource "aws_codebuild_project" "this" {
  # checkov:skip=CKV_AWS_147: No sensitive data is stored in the output artifacts
  name          = var.app_name
  description   = "Build project for ${var.app_name}"
  build_timeout = 5
  service_role  = aws_iam_role.this.arn

  artifacts {
    type = "CODEPIPELINE"
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
      group_name  = "Cloud-Build-${var.app_name}"
      stream_name = "log-stream"
    }

  }

  source {
    type = "CODEPIPELINE"
  }
  vpc_config {
    vpc_id = var.vpc_id

    subnets = var.private_subnet_ids

    security_group_ids = [
      var.code_build_security_group_id
    ]
  }
}