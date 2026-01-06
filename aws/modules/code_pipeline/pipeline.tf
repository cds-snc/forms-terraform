resource "aws_codepipeline" "this" {
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
      namespace        = "SourceVariables"

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.this.arn
        FullRepositoryId     = var.github_repo_name
        BranchName           = "main"
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "ECRBuildAndPublish"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ECRRepositoryName : var.app_ecr_name
      }
    }
  }

  # stage {
  #   name = "Deploy B/G"
  #   action {
  #     name = "Deploy"
  #     category = "Deploy"
  #     owner = "AWS"
  #     provider = "CodeDeployToECS"
  #     version = "1"
  #     input_artifacts = ["source_output"]
  #     configuration = {
  #       AppSpecTemplateArtifact: "source_output"
  #       ApplicationName: var.app_name
  #       DeploymentGroupName: ecs-deployment-group
  #       Image1ArtifactName: MyImage
  #       Image1ContainerName: IMAGE1_NAME
  #       TaskDefinitionTemplatePath: taskdef.json
  #       AppSpecTemplatePath: appspec.yaml
  #       TaskDefinitionTemplateArtifact: "source_output"
  #     }
  #   }
  # }

}
