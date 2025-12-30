locals {
  container_env = [
    {
      "name"  = "ZITADEL_API_URL",
      "value" = "http://zitadel.${var.service_discovery_private_dns_namespace_ecs_local_name}:8080"
    },
  ]
  container_secrets = [
    {
      "name"      = "ZITADEL_SERVICE_USER_TOKEN"
      "valueFrom" = aws_ssm_parameter.idp_login_service_user_token.arn
    },
  ]
}

module "idp_user_portal_ecs" {
  count = var.env == "staging" ? 1 : 0
  source = "github.com/cds-snc/terraform-modules//ecs?ref=825c15a16d794bd878e0d11555c0abe6f481f29e" # v10.10.2

  cluster_name = "idp"
  service_name = "user_portal"
  task_cpu     = 1024
  task_memory  = 2048

  service_use_latest_task_def = true

  # Scaling
  enable_autoscaling       = true
  desired_count            = 1
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 3

  # Task definition
  container_image       = "${var.idp_login_ecr_url}:latest"
  container_host_port   = 3000
  container_port        = 3000
  container_environment = local.container_env
  container_secrets     = local.container_secrets

  task_exec_role_policy_documents = [
    data.aws_iam_policy_document.idp_login_task_ssm_parameters.json
  ]

  # Networking
  lb_target_group_arn = aws_lb_target_group.user_portal[0].arn
  
  subnet_ids                     = var.private_subnet_ids
  security_group_ids             = [var.security_group_idp_ecs_id]
  service_discovery_enabled      = true
  service_discovery_namespace_id = var.service_discovery_private_dns_namespace_ecs_local_id

  # Logging
  cloudwatch_log_group_retention_in_days = 731

  billing_tag_key   = var.billing_tag_key
  billing_tag_value = var.billing_tag_value

## The Deploy pipeline will alternate between the target groups.
  lifecycle {
    ignore_changes = [
      lb_target_group_arn
    ]
  }
}

#
# IAM policies
#
data "aws_iam_policy_document" "idp_login_task_ssm_parameters" {
  statement {
    sid    = "GetSSMParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [
      aws_ssm_parameter.idp_login_service_user_token.arn
    ]
  }
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

