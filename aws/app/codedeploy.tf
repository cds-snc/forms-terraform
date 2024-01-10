#
# CodeDeploy
# Provides Blue/Green deployments for ECS tasks
#
resource "aws_codedeploy_app" "app" {
  compute_platform = "ECS"
  name             = "AppECS-${aws_ecs_cluster.forms.name}-${aws_ecs_service.form_viewer.name}"


}

resource "aws_codedeploy_deployment_group" "app" {
  app_name               = aws_codedeploy_app.app.name
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
