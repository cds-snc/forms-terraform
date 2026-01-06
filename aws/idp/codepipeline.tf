module "user_portal_code_pipeline" {
  source                         = "../modules/code_pipeline"
  vpc_id                         = var.vpc_id
  code_build_security_group_id   = var.code_build_security_group_id
  private_subnet_ids             = var.private_subnet_ids
  app_name                       = "idp_user_portal"
  github_repo_name               = "cds-snc/forms-idp-user-portal"
  webhook_secret                 = "SuperSecretString"
  app_ecr_name                   = "idp/user_portal"
  ecs_cluster_name               = aws_ecs_cluster.idp.name
  ecs_service_name               = aws_ecs_service.user_portal[0].name
  load_balancer_listener_arns    = [aws_lb_listener.idp.arn]
  loadblancer_target_group_names = aws_lb_target_group.user_portal[*].name

  depends_on = [ aws_ecs_service.user_portal, aws_ecs_cluster.idp,aws_lb_listener.idp,aws_lb_target_group.user_portal ]
}