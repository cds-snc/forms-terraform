# #
# # CodeDeploy
# # Provides Blue/Green deployments for ECS tasks
# #

resource "aws_codedeploy_app" "app" {
  compute_platform = "ECS"
  name             = "${var.app_name}"

}

resource "aws_codedeploy_deployment_group" "app" {
  app_name               = var.app_name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = var.app_name
  service_role_arn       = aws_iam_role.this.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.ecs_service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = var.load_balancer_listener_arns
      }

      dynamic "target_group" {
        for_each = var.loadblancer_target_group_names
        content {
          name = setting.value
        }
              }

    }
  }


}
