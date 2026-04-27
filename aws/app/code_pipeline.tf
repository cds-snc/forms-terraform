module "gc_forms_code_pipeline" {
  region                         = var.region
  source                         = "../modules/code_pipeline"
  vpc_id                         = var.vpc_id
  code_build_security_group_id   = var.code_build_security_group_id
  private_subnet_ids             = var.private_subnet_ids
  app_name                       = "gc-forms-web-app"
  github_repo_name               = "cds-snc/platform-forms-client"
  app_ecr_url                    = var.ecr_repository_url_form_viewer
  ecs_cluster_name               = aws_ecs_cluster.forms.name
  ecs_service_name               = aws_ecs_service.form_viewer.name
  app_container_name             = jsondecode(aws_ecs_task_definition.form_viewer.container_definitions)[1].name
  task_definition_family         = aws_ecs_task_definition.form_viewer.family
  load_balancer_listener_arns    = [var.lb_https_listener_arn]
  loadblancer_target_group_names = [var.lb_target_group_1_name, var.lb_target_group_2_name]
  build_compute_type             = "large"

  github_trigger = {
    mode             = var.env == "production" ? "DeployOnNewTag" : "DeployOnNewCommit"
    excludeFilePaths = var.env == "production" ? null : [".**", "__*/**", "tests/**"]
  }

  build_env_vars_from_secrets = [
    { key = "DATABASE_URL", secretArn = var.database_connection_url_secret_arn }, # This is required by the @gcforms/database package to run database migrations
  ]

  docker_build_args = [
    { key = "API_URL", value = "https://api.${var.domains[0]}" },
    { key = "COGNITO_APP_CLIENT_ID", value = var.cognito_client_id },
    { key = "COGNITO_USER_POOL_ID", value = var.cognito_user_pool_id },
    { key = "HCAPTCHA_SITE_KEY", value = var.hcaptcha_site_key },
    { key = "NEXT_DEPLOYMENT_ID", value = "$NEXT_DEPLOYMENT_ID" }, # $NEXT_DEPLOYMENT_ID is declared in the actual CodePipeline module definition (see aws/modules/code_pipeline/codebuild.tf)
    { key = "ZITADEL_URL", value = "https://auth.${var.domains[0]}" },
    { key = "ZITADEL_PROJECT_ID", value = var.zitadel_project_id }
  ]

  # Run database migration process
  custom_post_build_commands = [
    "yarn workspaces focus @gcforms/database",
    "yarn db:generate",
    "yarn db:prod"
  ]

  depends_on = [aws_ecs_service.form_viewer, aws_ecs_cluster.forms, aws_ecs_task_definition.form_viewer]
}
