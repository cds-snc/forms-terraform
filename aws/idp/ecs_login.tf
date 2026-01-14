locals {
  container_definitions = [{
    name      = "user_portal"
    cpu       = 1024
    memory    = 2048
    essential = true
    image     = "${var.idp_login_ecr_url}:latest"


    portMappings = [{
      containerPort : 3000,
      protocol : "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs",
      options = {
        awslogs-region        = var.region,
        awslogs-group         = aws_cloudwatch_log_group.user_portal.name,
        awslogs-stream-prefix = "task"
      }
    }

    readonlyRootFilesystem = true
    environment = [{
      "name"  = "ZITADEL_API_URL",
      "value" = "http://zitadel.${var.service_discovery_private_dns_namespace_ecs_local_name}:8080"
    }]
    secrets = [{
      "name"      = "ZITADEL_SERVICE_USER_TOKEN"
      "valueFrom" = aws_ssm_parameter.idp_login_service_user_token.arn
    }],

  }]
}


resource "aws_ecs_task_definition" "user_portal" {
  # checkov:skip=CKV_AWS_249: Different execution role ARN and task role ARN not required
  // TODO: Split roles for execution and task

  family       = "user_portal"
  cpu          = 1024
  memory       = 2048
  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.idp_user_portal.arn
  task_role_arn            = aws_iam_role.idp_user_portal.arn
  container_definitions    = jsonencode(local.container_definitions)
}

#
# Service
#
resource "aws_ecs_service" "user_portal" {
  count                = var.env == "production" ? 0 : 1
  name                 = "user_portal"
  cluster              = aws_ecs_cluster.idp.id
  task_definition      = aws_ecs_task_definition.user_portal.arn
  launch_type          = "FARGATE"
  platform_version     = "1.4.0"
  propagate_tags       = "SERVICE"
  force_new_deployment = true

  desired_count                     = 1
  health_check_grace_period_seconds = 60

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    assign_public_ip = false
    subnets          = var.private_subnet_ids
    security_groups  = [var.security_group_idp_ecs_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.user_portal[0].arn
    container_name   = "user_portal"
    container_port   = 3000
  }

  lifecycle {
    ignore_changes = [
      desired_count,   # updated by autoscaling
      task_definition, # updated by codedeploy
      load_balancer    # updated by codedeploy
    ]
  }
  depends_on = [aws_ecs_cluster.idp]

}

#
# Service autoscaling config
#
resource "aws_appautoscaling_target" "user_portal" {
  count = var.env == "production" ? 0 : 1

  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.idp.name}/${aws_ecs_service.user_portal[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 3
}

resource "aws_appautoscaling_policy" "user_portal_cpu" {
  count = var.env == "production" ? 0 : 1

  name               = "user_portal_cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.user_portal[0].service_namespace
  resource_id        = aws_appautoscaling_target.user_portal[0].resource_id
  scalable_dimension = aws_appautoscaling_target.user_portal[0].scalable_dimension

  target_tracking_scaling_policy_configuration {
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 25
  }
}

resource "aws_appautoscaling_policy" "user_portal_memory" {
  count = var.env == "production" ? 0 : 1

  name               = "user_portal_memory"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.user_portal[0].service_namespace
  resource_id        = aws_appautoscaling_target.user_portal[0].resource_id
  scalable_dimension = aws_appautoscaling_target.user_portal[0].scalable_dimension

  target_tracking_scaling_policy_configuration {
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 25
  }
}

#
# ECS task CloudWatch log group
#
resource "aws_cloudwatch_log_group" "user_portal" {
  name              = "user_portal"
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 731
}


#
# SSM Parameters
#
resource "aws_ssm_parameter" "idp_login_service_user_token" {
  # checkov:skip=CKV_AWS_337: Default SSM service key encryption is acceptable
  name  = "idp_login_service_user_token"
  type  = "SecureString"
  value = var.idp_login_service_user_token
  tags  = local.common_tags
}

