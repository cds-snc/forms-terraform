module "user_portal_code_pipeline" {
  count                          = var.env == "production" ? 0 : 1
  source                         = "../modules/code_pipeline"
  vpc_id                         = var.vpc_id
  code_build_security_group_id   = var.code_build_security_group_id
  private_subnet_ids             = var.private_subnet_ids
  app_name                       = "idp-user-portal"
  github_repo_name               = "cds-snc/platform-unified-accounts-user-portal"
  app_ecr_name                   = "idp/user_portal"
  app_ecr_url                    = var.idp_login_ecr_url
  ecs_cluster_name               = aws_ecs_cluster.idp.name
  ecs_service_name               = aws_ecs_service.user_portal[0].name
  app_container_name             = local.container_definitions[0].name
  task_definition_family         = aws_ecs_task_definition.user_portal.family
  load_balancer_listener_arns    = [aws_lb_listener.idp.arn]
  loadblancer_target_group_names = aws_lb_target_group.user_portal[*].name

  github_trigger = {
    mode = "DeployOnNewCommit"
  }

  depends_on = [aws_ecs_service.user_portal, aws_ecs_cluster.idp, aws_lb_listener.idp, aws_lb_target_group.user_portal, aws_ecs_task_definition.user_portal]
}
