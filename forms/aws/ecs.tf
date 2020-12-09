###
# ECS Cluster
###

resource "aws_ecs_cluster" "forms" {
  name = var.ecs_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

locals {
  portal_repo = aws_ecr_repository.repository.repository_url
}

###
# ECS - Forms End User
###

# Task Definition

data "template_file" "forms_task" {
  template = file("task-definitions/forms.json")

  vars = {
    image                 = "${local.portal_repo}"
    awslogs-group         = aws_cloudwatch_log_group.forms.name
    awslogs-region        = var.region
    awslogs-stream-prefix = "ecs-${var.ecs_forms_name}"
    metric_provider       = var.metric_provider
    tracer_provider       = var.tracer_provider
    notify_api_key        = aws_secretsmanager_secret_version.notify_api_key.arn
  }
}

resource "aws_ecs_task_definition" "forms" {
  family       = var.ecs_forms_name
  cpu          = 2048
  memory       = "4096"
  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.forms.arn
  task_role_arn            = aws_iam_role.forms.arn
  container_definitions    = data.template_file.forms_task.rendered

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

# Service

resource "aws_ecs_service" "forms" {
  depends_on = [
    aws_lb_listener.forms_https,
    aws_lb_listener.forms_http
  ]

  name             = var.ecs_forms_name
  cluster          = aws_ecs_cluster.forms.id
  task_definition  = aws_ecs_task_definition.forms.arn
  launch_type      = "FARGATE"
  platform_version = "1.4.0"
  # Enable the new ARN format to propagate tags to containers (see config/terraform/aws/README.md)
  propagate_tags = "SERVICE"

  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 100
  health_check_grace_period_seconds  = 60
  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    assign_public_ip = false
    subnets          = aws_subnet.forms_private.*.id
    security_groups = [
      aws_security_group.forms.id,
      aws_security_group.forms_egress.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.forms.arn
    container_name   = "forms-end-user"
    container_port   = 3000
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }

  lifecycle {
    ignore_changes = [
      desired_count,   # updated by autoscaling
      task_definition, # updated by codedeploy
      load_balancer    # updated by codedeploy
    ]
  }

}

resource "aws_appautoscaling_target" "portal" {
  count              = var.forms_autoscale_enabled ? 1 : 0
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_service.forms.cluster}/${aws_ecs_service.forms.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
}
resource "aws_appautoscaling_policy" "portal_cpu" {
  count              = var.portal_autoscale_enabled ? 1 : 0
  name               = "forms_cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_service.forms.cluster}/${aws_ecs_service.forms.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  target_tracking_scaling_policy_configuration {
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.cpu_scale_metric
  }
}

resource "aws_appautoscaling_policy" "portal_memory" {
  count              = var.forms_autoscale_enabled ? 1 : 0
  name               = "forms_memory"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_service.forms.cluster}/${aws_ecs_service.forms.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  target_tracking_scaling_policy_configuration {
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.memory_scale_metric
  }
}
