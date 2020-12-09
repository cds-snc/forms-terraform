module "forms" {
  source                           = "./modules/codedeploy"
  codedeploy_service_role_arn      = aws_iam_role.codedeploy.arn
  action_on_timeout                = var.manual_deploy_enabled ? "STOP_DEPLOYMENT" : "CONTINUE_DEPLOYMENT"
  termination_wait_time_in_minutes = var.termination_wait_time_in_minutes
  cluster_name                     = aws_ecs_cluster.forms.name
  ecs_service_name                 = aws_ecs_service.forms.name
  lb_listener_arns                 = [aws_lb_listener.forms_https.arn]
  aws_lb_target_group_blue_name    = aws_lb_target_group.forms.name
  aws_lb_target_group_green_name   = aws_lb_target_group.forms_2.name
}
