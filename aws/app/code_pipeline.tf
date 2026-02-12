#
# Only use Blue/Gree deployment with CodeDeploy in Production while we test the new full deployment pipeline in Staging using our code_pipeline module.
#
resource "aws_codedeploy_app" "app" {
  count = var.env == "production" ? 1 : 0

  compute_platform = "ECS"
  name             = "AppECS-${aws_ecs_cluster.forms.name}-${aws_ecs_service.form_viewer.name}"
}

resource "aws_codedeploy_deployment_group" "app" {
  count = var.env == "production" ? 1 : 0

  app_name               = aws_codedeploy_app.app[0].name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "DgpECS-${aws_ecs_cluster.forms.name}-${aws_ecs_service.form_viewer.name}"
  service_role_arn       = aws_iam_role.codedeploy.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = var.codedeploy_manual_deploy_enabled ? "STOP_DEPLOYMENT" : "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = var.codedeploy_termination_wait_time_in_minutes
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.forms.name
    service_name = aws_ecs_service.form_viewer.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.lb_https_listener_arn]
      }

      target_group {
        name = var.lb_target_group_1_name
      }

      target_group {
        name = var.lb_target_group_2_name
      }
    }
  }
}

module "gc_forms_code_pipeline" {
  count = var.env == "production" ? 0 : 1

  source                         = "../modules/code_pipeline"
  vpc_id                         = var.vpc_id
  code_build_security_group_id   = var.code_build_security_group_id
  private_subnet_ids             = var.private_subnet_ids
  app_name                       = "gc-forms-web-app"
  github_repo_name               = "cds-snc/platform-forms-client"
  app_ecr_name                   = var.ecr_form_viewer_repository_name
  app_ecr_url                    = var.ecr_repository_url_form_viewer
  ecs_cluster_name               = aws_ecs_cluster.forms.name
  ecs_service_name               = aws_ecs_service.form_viewer.name
  app_container_name             = jsondecode(aws_ecs_task_definition.form_viewer.container_definitions)[1].name
  task_definition_family         = aws_ecs_task_definition.form_viewer.family
  load_balancer_listener_arns    = [var.lb_https_listener_arn]
  loadblancer_target_group_names = [var.lb_target_group_1_name, var.lb_target_group_2_name]

  build_env_vars_from_secrets = [
    { key = "DATABASE_URL", secretArn = var.database_url_secret_arn }
  ]

  docker_build_args = [
    { key = "API_URL", value = "https://api.${var.domains[0]}" },
    { key = "COGNITO_APP_CLIENT_ID", value = var.cognito_client_id },
    { key = "COGNITO_USER_POOL_ID", value = var.cognito_user_pool_id },
    { key = "HCAPTCHA_SITE_KEY", value = var.hcaptcha_site_key },
    { key = "NEXT_DEPLOYMENT_ID", value = var.env == "production" ? "$GIT_TAG" : "$GIT_COMMIT_ID" },
    { key = "ZITADEL_URL", value = "https://auth.${var.domains[0]}" },
    { key = "ZITADEL_PROJECT_ID", value = var.zitadel_project_id }
  ]

  custom_build_commands = [
    "yarn install",
    "yarn prisma:generate",
    "yarn prisma:deploy"
  ]

  depends_on = [aws_ecs_service.form_viewer, aws_ecs_cluster.forms, aws_ecs_task_definition.form_viewer]
}
