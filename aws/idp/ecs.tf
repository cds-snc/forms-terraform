locals {
  container_env = [
    {
      "name"  = "ZITADEL_DATABASE_POSTGRES_PORT",
      "value" = "5432"
    },
    {
      "name"  = "ZITADEL_DATABASE_POSTGRES_ADMIN_SSL_MODE",
      "value" = "require"
    },
    {
      "name"  = "ZITADEL_DATABASE_POSTGRES_USER_SSL_MODE",
      "value" = "require"
    },
    {
      "name"  = "ZITADEL_EXTERNALDOMAIN",
      "value" = var.domain_idp
    },
    {
      "name"  = "ZITADEL_EXTERNALPORT",
      "value" = "443"
    },
    {
      "name"  = "ZITADEL_EXTERNALSECURE",
      "value" = "true"
    },
    {
      "name"  = "ZITADEL_FIRSTINSTANCE_ORG_NAME",
      "value" = "cds-snc"
    },
    {
      "name"  = "ZITADEL_FIRSTINSTANCE_ORG_HUMAN_PASSWORDCHANGEREQUIRED",
      "value" = "false"
    },
    {
      "name"  = "ZITADEL_PORT",
      "value" = "8080"
    },
    {
      "name"  = "ZITADEL_TLS_KEYPATH",
      "value" = "/usr/local/share/ca-certificates/private.key"
    },
    {
      "name"  = "ZITADEL_TLS_CERTPATH",
      "value" = "/usr/local/share/ca-certificates/certificate.crt"
    },
  ]
  container_secrets = [
    {
      "name"      = "ZITADEL_DATABASE_POSTGRES_DATABASE"
      "valueFrom" = aws_ssm_parameter.zitadel_database_name.arn
    },
    {
      "name"      = "ZITADEL_DATABASE_POSTGRES_HOST"
      "valueFrom" = aws_ssm_parameter.zitadel_database_host.arn
    },
    {
      "name"      = "ZITADEL_DATABASE_POSTGRES_USER_USERNAME"
      "valueFrom" = aws_ssm_parameter.zitadel_database_user_username.arn
    },
    {
      "name"      = "ZITADEL_DATABASE_POSTGRES_USER_PASSWORD"
      "valueFrom" = aws_ssm_parameter.zitadel_database_user_password.arn
    },
    {
      "name"      = "ZITADEL_DATABASE_POSTGRES_ADMIN_USERNAME"
      "valueFrom" = aws_ssm_parameter.idp_database_cluster_admin_username.arn
    },
    {
      "name"      = "ZITADEL_DATABASE_POSTGRES_ADMIN_PASSWORD"
      "valueFrom" = aws_ssm_parameter.idp_database_cluster_admin_password.arn
    },
    {
      "name"      = "ZITADEL_FIRSTINSTANCE_ORG_HUMAN_USERNAME"
      "valueFrom" = aws_ssm_parameter.zitadel_admin_username.arn
    },
    {
      "name"      = "ZITADEL_FIRSTINSTANCE_ORG_HUMAN_PASSWORD"
      "valueFrom" = aws_ssm_parameter.zitadel_admin_password.arn
    },
    {
      "name"      = "ZITADEL_MASTERKEY"
      "valueFrom" = aws_ssm_parameter.zitadel_secret_key.arn
    },
  ]
}

module "idp_ecs" {
  source = "github.com/cds-snc/terraform-modules//ecs?ref=544060caeadb399c773247e2c25640e0c62fb0ed" # v9.5.3

  cluster_name = "idp"
  service_name = "zitadel"
  task_cpu     = 1024
  task_memory  = 2048

  # Scaling
  enable_autoscaling       = true
  desired_count            = 1
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 3

  # Task definition
  container_image       = "${var.zitadel_image_ecr_url}:${var.zitadel_image_tag}"
  container_command     = ["start-from-init", "--masterkeyFromEnv", "--tlsMode", "enabled"] # TODO: update to `start` command only for prod
  container_host_port   = 8080
  container_port        = 8080
  container_environment = local.container_env
  container_secrets     = local.container_secrets

  task_exec_role_policy_documents = [
    data.aws_iam_policy_document.ecs_task_ssm_parameters.json
  ]

  # Networking
  lb_target_group_arn = aws_lb_target_group.idp.arn
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.security_group_idp_ecs_id]

  billing_tag_key   = var.billing_tag_key
  billing_tag_value = var.billing_tag_value
}

#
# IAM policies
#
data "aws_iam_policy_document" "ecs_task_ssm_parameters" {
  statement {
    sid    = "GetSSMParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [
      aws_ssm_parameter.idp_database_cluster_admin_username.arn,
      aws_ssm_parameter.idp_database_cluster_admin_password.arn,
      aws_ssm_parameter.zitadel_admin_username.arn,
      aws_ssm_parameter.zitadel_admin_password.arn,
      aws_ssm_parameter.zitadel_database_host.arn,
      aws_ssm_parameter.zitadel_database_name.arn,
      aws_ssm_parameter.zitadel_database_user_username.arn,
      aws_ssm_parameter.zitadel_database_user_password.arn,
      aws_ssm_parameter.zitadel_secret_key.arn
    ]
  }
}

#
# SSM Parameters
#
resource "aws_ssm_parameter" "zitadel_secret_key" {
  # checkov:skip=CKV_AWS_337: Default SSM service key encryption is acceptable
  name  = "zitadel_secret_key"
  type  = "SecureString"
  value = var.zitadel_secret_key
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "zitadel_admin_username" {
  # checkov:skip=CKV_AWS_337: Default SSM service key encryption is acceptable
  name  = "zitadel_admin_username"
  type  = "SecureString"
  value = var.zitadel_admin_username
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "zitadel_admin_password" {
  # checkov:skip=CKV_AWS_337: Default SSM service key encryption is acceptable
  name  = "zitadel_admin_password"
  type  = "SecureString"
  value = var.zitadel_admin_password
  tags  = local.common_tags
}
