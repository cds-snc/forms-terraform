# # #
# # # CodeDeploy
# # # Provides Blue/Green deployments for ECS tasks
# # #

resource "aws_codedeploy_app" "this" {
  compute_platform = "ECS"
  name             = var.app_name
}

resource "aws_codedeploy_deployment_group" "this" {
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
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 1
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
          name = target_group.value
        }
      }

    }
  }
}


locals {
  appspec = <<EOT
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        PlatformVersion: LATEST
        TaskDefinition: <TASK_DEFINITION>
        LoadBalancerInfo:
          ContainerName: ${var.app_container_name}
          ContainerPort: ${data.aws_lb_target_group.this.port}
EOT
}

