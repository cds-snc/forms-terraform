
resource "aws_codebuild_project" "build_image" {
  # checkov:skip=CKV_AWS_147: No sensitive data is stored in the output artifacts
  name          = "Image-Build-${var.app_name}"
  description   = "Build Docker Image for ${var.app_name}"
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
      stream_name = "image-build"
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

resource "aws_codebuild_project" "ecs_render" {
  # checkov:skip=CKV_AWS_147: No sensitive data is stored in the output artifacts
  name          = "ECS-Render-${var.app_name}"
  description   = "Render ECS files for ${var.app_name}"
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
    privileged_mode = true
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "Cloud-Build-${var.app_name}"
      stream_name = "ecs-render"
    }

  }

  source {
    type      = "CODEPIPELINE"
    buildspec = local.buildspec
  }
  vpc_config {
    vpc_id = var.vpc_id

    subnets = var.private_subnet_ids

    security_group_ids = [
      var.code_build_security_group_id
    ]
  }
}

locals {
  buildspec = jsonencode({
    version = 0.2
    env = {
      variables         =  { for item in var.docker_build_env_vars_plaintext : item.key => item.value }
      "parameter-store" = { for item in var.docker_build_env_vars_parameter_store : item.key => item.value }      
      "secrets-manager" = { for item in var.docker_build_env_vars_secrets : item.key => item.value }      
    }
    phases = {
      build = {
        "on-failure" = "ABORT"
        commands = [
          "aws ecr get-login-password --region ca-central-1 | docker login --username AWS --password-stdin ${var.app_ecr_url}",
          "docker build -t base ${local.docker_build_args}",
          "docker tag base ${var.app_ecr_url}:latest",
          "docker push ${var.app_ecr_url}:latest",
          "docker tag base ${var.app_ecr_url}:$GIT_COMMIT_ID",
          "docker push ${var.app_ecr_url}:$GIT_COMMIT_ID",
          "export GIT_TAG=$(git tag --points-at $GIT_COMMIT_ID)",
          "if [[ -n \"$GIT_TAG\" ]]; then docker tag base ${var.app_ecr_url}:$GIT_TAG && docker push ${var.app_ecr_url}:$GIT_TAG; fi"
        ]
        finally = [
          "docker logout ${var.app_ecr_url}"
        ]
      }
      post_build = {
        "on-failure" = "ABORT"
        commands = [
          "printf \"$APPSPEC\" > appspec.yaml",
          "aws ecs describe-task-definition --task-definition ${var.task_definition_family} --query taskDefinition | jq --arg gitCommit \"$GIT_COMMIT_ID\" '.taskDefinitionArn |= \"${data.aws_ecs_task_definition.this.arn_without_revision}\" | .containerDefinitions |= map(select(.name == \"${var.app_container_name}\").image |= \"${var.app_ecr_url}:\" + $gitCommit)' > task_definition.json"
        ]

      }
    }
    artifacts = {
      files = ["appspec.yaml", "task_definition.json"]
    }
  })
  docker_build_args = join(" ", [for instance in concat(var.docker_build_env_vars_plaintext, var.docker_build_env_vars_parameter_store, var.docker_build_env_vars_secrets) : "--build-arg ${instance.key}=${instance.value}"],["."])
}
