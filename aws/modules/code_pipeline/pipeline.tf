resource "aws_codepipeline" "this" {
  # checkov:skip=CKV_AWS_219: No sensitive values are stored in artifacts
  name          = "${var.app_name}-pipeline"
  role_arn      = aws_iam_role.this.arn
  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      namespace        = "GitSource"

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.this.arn
        FullRepositoryId     = var.github_repo_name
        BranchName           = "main"
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Render_For_ECS"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      version          = "1"
      namespace        = "RenderSource"
      output_artifacts = ["render_output"]
      run_order        = 1

      configuration = {
        PrimarySource = "GitSource"
        ProjectName   = aws_codebuild_project.ecs_render.name
        EnvironmentVariables = jsonencode([
          { name : "GIT_COMMIT_ID", value : "#{GitSource.CommitId}", type : "PLAINTEXT" },
          { name : "TASKDEF_FAMILY", value : var.task_definition_family, type : "PLAINTEXT" },
          { name : "APPSPEC", value : local.appspec, type : "PLAINTEXT" }
        ])
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      input_artifacts = ["render_output"]
      configuration = {
        ApplicationName : aws_codedeploy_app.this.name
        DeploymentGroupName : aws_codedeploy_deployment_group.this.deployment_group_name
        AppSpecTemplateArtifact : "render_output"
        AppSpecTemplatePath : "appspec.yaml"
        TaskDefinitionTemplateArtifact : "render_output"
        TaskDefinitionTemplatePath : "task_definition.json"
      }
    }
  }
}
