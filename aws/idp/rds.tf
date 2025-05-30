#
# RDS Postgress cluster
#
module "idp_database" {
  source = "github.com/cds-snc/terraform-modules//rds?ref=64b19ecfc23025718cd687e24b7115777fd09666" # v10.2.1
  name   = "idp"

  database_name           = var.zitadel_database_name
  engine                  = "aurora-postgresql"
  engine_version          = "16.6"
  instances               = 1 # TODO: increase for prod loads
  instance_class          = "db.serverless"
  serverless_min_capacity = var.idp_database_min_acu
  serverless_max_capacity = var.idp_database_max_acu

  username               = var.idp_database_cluster_admin_username
  password               = var.idp_database_cluster_admin_password
  proxy_secret_auth_arns = [aws_secretsmanager_secret.zidatel_database_proxy_auth.arn]

  backup_retention_period      = 14
  preferred_backup_window      = "02:00-04:00"
  performance_insights_enabled = false

  vpc_id             = var.vpc_id
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [var.security_group_idp_db_id]

  billing_tag_key   = var.billing_tag_key
  billing_tag_value = var.billing_tag_value
}

resource "aws_ssm_parameter" "idp_database_cluster_admin_username" {
  # checkov:skip=CKV_AWS_337: Default SSM service key encryption is acceptable
  name  = "idp_database_cluster_admin_username"
  type  = "SecureString"
  value = var.idp_database_cluster_admin_username
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "idp_database_cluster_admin_password" {
  # checkov:skip=CKV_AWS_337: Default SSM service key encryption is acceptable
  name  = "idp_database_cluster_admin_password"
  type  = "SecureString"
  value = var.idp_database_cluster_admin_password
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "zitadel_database_host" {
  # checkov:skip=CKV_AWS_337: Default SSM service key encryption is acceptable
  name  = "zitadel_database_host"
  type  = "SecureString"
  value = module.idp_database.proxy_endpoint
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "zitadel_database_name" {
  # checkov:skip=CKV_AWS_337: Default SSM service key encryption is acceptable
  name  = "zitadel_database_name"
  type  = "SecureString"
  value = var.zitadel_database_name
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "zitadel_database_user_username" {
  # checkov:skip=CKV_AWS_337: Default SSM service key encryption is acceptable
  name  = "zitadel_database_user_username"
  type  = "SecureString"
  value = var.zitadel_database_user_username
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "zitadel_database_user_password" {
  # checkov:skip=CKV_AWS_337: Default SSM service key encryption is acceptable
  name  = "zitadel_database_user_password"
  type  = "SecureString"
  value = var.zitadel_database_user_password
  tags  = local.common_tags
}

resource "aws_secretsmanager_secret" "zidatel_database_proxy_auth" {
  # checkov:skip=CKV2_AWS_57: automated rotation is not applicable to this secret
  name = "zidatel_database_proxy_auth"
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "zidatel_database_proxy_auth" {
  secret_id = aws_secretsmanager_secret.zidatel_database_proxy_auth.id
  secret_string = jsonencode({
    username = var.zitadel_database_user_username,
    password = var.zitadel_database_user_password
  })
}
