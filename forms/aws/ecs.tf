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
  form_viewer_repo = aws_ecr_repository.viewer_repository.repository_url
}

###
# ECS - Forms End User
###

# Task Definition

data "template_file" "form_viewer_task" {
  template = file("task-definitions/form_viewer.json")

  vars = {
    image                    = local.form_viewer_repo
    awslogs-group            = aws_cloudwatch_log_group.forms.name
    awslogs-region           = var.region
    awslogs-stream-prefix    = "ecs-${var.ecs_form_viewer_name}"
    metric_provider          = var.metric_provider
    tracer_provider          = var.tracer_provider
    notify_api_key           = aws_secretsmanager_secret_version.notify_api_key.arn
    google_client_id         = aws_secretsmanager_secret_version.google_client_id.arn
    google_client_secret     = aws_secretsmanager_secret_version.google_client_secret.arn
    database_url             = aws_secretsmanager_secret_version.database_url.arn
    redis_url                = aws_elasticache_replication_group.redis.primary_endpoint_address
    token_secret             = awa_secretsmanager_secret_version.token_secret.arn
    nextauth_url             = "https://${var.route53_zone_name}"
    submission_api           = aws_lambda_function.submission.arn
    templates_api            = aws_lambda_function.templates.arn
    organisations_api        = aws_lambda_function.organisations.arn
    reliability_file_storage = aws_s3_bucket.reliability_file_storage.id
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
  }
}

# Service

resource "aws_ecs_service" "form_viewer" {
  depends_on = [
    aws_lb_listener.form_viewer_https,
    aws_lb_listener.form_viewer_http
  ]

  name             = var.ecs_form_viewer_name
  cluster          = aws_ecs_cluster.forms.id
  task_definition  = aws_ecs_task_definition.form_viewer.arn
  launch_type      = "FARGATE"
  platform_version = "1.4.0"
  # Enable the new ARN format to propagate tags to containers (see config/terraform/aws/README.md)
  propagate_tags = "SERVICE"

  desired_count                     = 1
  health_check_grace_period_seconds = 60
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
    target_group_arn = aws_lb_target_group.form_viewer.arn
    container_name   = "form_viewer"
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

resource "aws_appautoscaling_target" "forms" {
  count              = var.form_viewer_autoscale_enabled ? 1 : 0
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_service.form_viewer.cluster}/${aws_ecs_service.form_viewer.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
}
resource "aws_appautoscaling_policy" "forms_cpu" {
  count              = var.form_viewer_autoscale_enabled ? 1 : 0
  name               = "forms_cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_service.form_viewer.cluster}/${aws_ecs_service.form_viewer.name}"
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

resource "aws_appautoscaling_policy" "forms_memory" {
  count              = var.form_viewer_autoscale_enabled ? 1 : 0
  name               = "forms_memory"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_service.form_viewer.cluster}/${aws_ecs_service.form_viewer.name}"
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

## IAM Polcies

data "aws_iam_policy_document" "forms" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

###
# AWS IAM - Forms End User
###

resource "aws_iam_role" "forms" {
  name = var.ecs_form_viewer_name

  assume_role_policy = data.aws_iam_policy_document.forms.json

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_iam_policy" "forms_secrets_manager" {
  name   = "formsSecretsManagerKeyRetrieval"
  path   = "/"
  policy = data.aws_iam_policy_document.forms_secrets_manager.json
}

data "aws_iam_policy_document" "forms_secrets_manager" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      aws_secretsmanager_secret_version.notify_api_key.arn,
      aws_secretsmanager_secret_version.google_client_id.arn,
      aws_secretsmanager_secret_version.google_client_secret.arn,
      aws_secretsmanager_secret_version.database_url.arn,
      aws_secretsmanager_secret_version.token_secret.arn
    ]
  }
}


resource "aws_iam_policy" "forms_s3" {
  name   = "formsS3Access"
  path   = "/"
  policy = data.aws_iam_policy_document.forms_s3.json
}

data "aws_iam_policy_document" "forms_s3" {
  statement {
    effect = "Allow"

    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.reliability_file_storage.arn,
      "${aws_s3_bucket.reliability_file_storage.arn}/*"
    ]
  }
}


resource "aws_iam_role_policy_attachment" "ecs_task_execution_forms" {
  role       = aws_iam_role.forms.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "secrets_manager_forms" {
  role       = aws_iam_role.forms.name
  policy_arn = aws_iam_policy.forms_secrets_manager.arn
}

resource "aws_iam_role_policy_attachment" "s3_forms" {
  role       = aws_iam_role.forms.name
  policy_arn = aws_iam_policy.forms_s3.arn
}
