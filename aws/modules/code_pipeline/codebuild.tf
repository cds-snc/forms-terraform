resource "aws_codebuild_project" "ecs_render" {
  # checkov:skip=CKV_AWS_147: No sensitive data is stored in the output artifacts
  # checkov:skip=CKV_AWS_316: Privileges required to build docker container within codebuild environment
  name          = "ECS-Render-${var.app_name}"
  description   = "Render ECS files for ${var.app_name}"
  build_timeout = 10
  service_role  = aws_iam_role.this.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type = "NO_CACHE"
  }

  environment {
    compute_type                = var.build_compute_type == "large" ? "BUILD_GENERAL1_MEDIUM" : "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:6.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
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

  depends_on = [aws_iam_role_policy.codepipeline_policy]
}

locals {
  docker_build_args = join(" ", [for instance in var.docker_build_args : "--build-arg ${instance.key}=${instance.value}"])

  base_build_commands = [
    "export GIT_TAG=$(git tag --points-at $GIT_COMMIT_ID | head -n 1)", # Check if a GIT_TAG exist. This would mean that CodePipeline was triggered by a Production release
    "export RELEASE_IDENTIFIER=$${GIT_TAG:-$GIT_COMMIT_ID}",            # Create RELEASE_IDENTIFIER which will be used by the rest of the deployment pipeline to either reference a Git tag (production) or commit identifier (staging)
    "export NEXT_DEPLOYMENT_ID=$${RELEASE_IDENTIFIER//./-}",            # This is used in aws/app/code_pipeline.tf. We should be able to delete it once we get rid of Rainbow deployments (context: https://github.com/cds-snc/platform-forms-client/pull/6908)
    "aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.app_ecr_url}",
    "docker build -t base ${local.docker_build_args} .",
    "docker tag base ${var.app_ecr_url}:latest && docker push ${var.app_ecr_url}:latest",
    "docker tag base ${var.app_ecr_url}:$RELEASE_IDENTIFIER && docker push ${var.app_ecr_url}:$RELEASE_IDENTIFIER"
  ]

  base_post_build_commands = [
    "printf \"$APPSPEC\" > appspec.yaml",
    "aws ecs describe-task-definition --task-definition ${var.task_definition_family} --query taskDefinition | jq --arg releaseIdentifier \"$RELEASE_IDENTIFIER\" '.taskDefinitionArn |= \"${data.aws_ecs_task_definition.this.arn_without_revision}\" | .containerDefinitions |= map(select(.name == \"${var.app_container_name}\").image |= \"${var.app_ecr_url}:\" + $releaseIdentifier)' > task_definition.json"
  ]

  post_build_commands = concat(local.base_post_build_commands, var.custom_post_build_commands)

  buildspec = jsonencode({
    version = 0.2
    env = {
      variables         = { for item in var.build_env_vars_plaintext : item.key => item.value }
      "parameter-store" = { for item in var.build_env_vars_from_parameter_store : item.key => item.parameterName }
      "secrets-manager" = { for item in var.build_env_vars_from_secrets : item.key => item.secretArn }
    }
    phases = {
      build = {
        "on-failure" = "ABORT"
        commands     = local.base_build_commands
        finally = [
          "docker logout ${var.app_ecr_url}"
        ]
      }
      post_build = {
        "on-failure" = "ABORT"
        commands     = local.post_build_commands
      }
    }
    artifacts = {
      files = ["appspec.yaml", "task_definition.json"]
    }
  })
}
