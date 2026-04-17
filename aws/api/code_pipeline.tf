module "code_pipeline" {
  source                         = "../modules/code_pipeline"
  vpc_id                         = var.vpc_id
  code_build_security_group_id   = var.code_build_security_group_id
  private_subnet_ids             = var.private_subnet_ids
  app_name                       = "gc-forms-api"
  github_repo_name               = "cds-snc/forms-api"
  app_ecr_url                    = var.api_image_ecr_url
  ecs_cluster_name               = var.ecs_cluster_name
  ecs_service_name               = var.ecs_service_name
  app_container_name             = var.ecs_service_name
  task_definition_family         = module.api_ecs.task_definition_family
  load_balancer_listener_arns    = [var.lb_https_listener_arn]                              # TODO
  loadblancer_target_group_names = [var.lb_target_group_1_name, var.lb_target_group_2_name] # TODO

  github_trigger = {
    mode             = var.env == "production" ? "DeployOnNewTag" : "DeployOnNewCommit"
    excludeFilePaths = var.env == "production" ? null : ["tests/**"]
  }

  depends_on = [module.api_ecs]
}
