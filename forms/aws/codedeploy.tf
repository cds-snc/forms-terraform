module "forms" {
  source                           = "./modules/codedeploy"
  codedeploy_service_role_arn      = aws_iam_role.codedeploy.arn
  action_on_timeout                = var.manual_deploy_enabled ? "STOP_DEPLOYMENT" : "CONTINUE_DEPLOYMENT"
  termination_wait_time_in_minutes = var.termination_wait_time_in_minutes
  cluster_name                     = aws_ecs_cluster.forms.name
  ecs_service_name                 = aws_ecs_service.form_viewer.name
  lb_listener_arns                 = [aws_lb_listener.form_viewer_https.arn]
  aws_lb_target_group_blue_name    = aws_lb_target_group.form_viewer.name
  aws_lb_target_group_green_name   = aws_lb_target_group.form_viewer_2.name
}


###
# AWS IAM - Codedeploy
###

resource "aws_iam_role" "codedeploy" {
  name               = "codedeploy"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_codedeploy.json
  path               = "/"
}

data "aws_iam_policy_document" "assume_role_policy_codedeploy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}