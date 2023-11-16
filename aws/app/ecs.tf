#
# ECS Cluster
# Fargate cluster that runs the Form viewer app
#
resource "aws_ecs_cluster" "forms" {
  name = var.ecs_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

#
# Task Definition
#
data "template_file" "form_viewer_task" {
  template = file("ecs_task/form_viewer.json")

  vars = {
    image                           = var.ecr_repository_url_form_viewer
    awslogs-group                   = aws_cloudwatch_log_group.forms.name
    awslogs-region                  = var.region
    awslogs-stream-prefix           = "ecs-${var.ecs_form_viewer_name}"
    metric_provider                 = var.metric_provider
    tracer_provider                 = var.tracer_provider
    notify_api_key                  = var.notify_api_key_secret
    freshdesk_api_key               = var.freshdesk_api_key_secret
    recaptcha_secret                = var.recaptcha_secret
    recaptcha_public                = var.recaptcha_public
    gc_notify_callback_bearer_token = var.notify_callback_bearer_token_secret
    token_secret                    = var.ecs_token_secret
    database_url                    = var.database_url_secret_arn
    redis_url                       = var.redis_url
    nextauth_url                    = "https://${var.domains[0]}"
    reliability_file_storage        = var.reliability_file_storage_id
    vault_file_storage              = var.vault_file_storage_id
    gc_temp_token_template_id       = var.gc_temp_token_template_id
    gc_template_id                  = var.gc_template_id
    cognito_endpoint_url            = var.cognito_endpoint_url
    cognito_client_id               = var.cognito_client_id
    email_address_contact_us        = var.email_address_contact_us
    email_address_support           = var.email_address_support
    reprocess_submission_queue      = var.sqs_reprocess_submission_queue_id
    audit_log_queue_url             = var.sqs_audit_log_queue_id
  }
}

resource "aws_ecs_task_definition" "form_viewer" {
  family       = var.ecs_form_viewer_name
  cpu          = 2048
  memory       = "4096"
  network_mode = "awsvpc"

  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.forms.arn
  task_role_arn            = aws_iam_role.forms.arn
  container_definitions    = data.template_file.form_viewer_task.rendered

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

#
# Service
#
resource "aws_ecs_service" "form_viewer" {
  name             = var.ecs_form_viewer_name
  cluster          = aws_ecs_cluster.forms.id
  task_definition  = aws_ecs_task_definition.form_viewer.arn
  launch_type      = "FARGATE"
  platform_version = "1.4.0"
  propagate_tags   = "SERVICE"

  desired_count                     = 1
  health_check_grace_period_seconds = 60

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    assign_public_ip = false
    subnets          = var.private_subnet_ids
    security_groups = [
      var.ecs_security_group_id,
      var.egress_security_group_id
    ]
  }

  load_balancer {
    target_group_arn = var.lb_target_group_1_arn
    container_name   = "form_viewer"
    container_port   = 3000
  }

  lifecycle {
    ignore_changes = [
      desired_count,   # updated by autoscaling
      task_definition, # updated by codedeploy
      load_balancer    # updated by codedeploy
    ]
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

#
# Service autoscaling config
#
resource "aws_appautoscaling_target" "forms" {
  count              = var.ecs_autoscale_enabled ? 1 : 0
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_service.form_viewer.cluster}/${aws_ecs_service.form_viewer.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.ecs_min_tasks
  max_capacity       = var.ecs_max_tasks
}

resource "aws_appautoscaling_policy" "forms_cpu" {
  count              = var.ecs_autoscale_enabled ? 1 : 0
  name               = "forms_cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_service.form_viewer.cluster}/${aws_ecs_service.form_viewer.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  target_tracking_scaling_policy_configuration {
    scale_in_cooldown  = var.ecs_scale_in_cooldown
    scale_out_cooldown = var.ecs_scale_out_cooldown
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.ecs_scale_cpu_threshold
  }
}

resource "aws_appautoscaling_policy" "forms_memory" {
  count              = var.ecs_autoscale_enabled ? 1 : 0
  name               = "forms_memory"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_service.form_viewer.cluster}/${aws_ecs_service.form_viewer.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  target_tracking_scaling_policy_configuration {
    scale_in_cooldown  = var.ecs_scale_in_cooldown
    scale_out_cooldown = var.ecs_scale_out_cooldown
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.ecs_scale_memory_threshold
  }
}

#
# ECS task CloudWatch log group
#
resource "aws_cloudwatch_log_group" "forms" {
  name              = var.ecs_name
  kms_key_id        = var.kms_key_cloudwatch_arn
  retention_in_days = 90

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}
