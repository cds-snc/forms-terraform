locals {
  container_env = [
    {
      name  = "ZITADEL_DOMAIN"
      value = var.zitadel_provider
    }
  ]

  container_secrets = [
    {
      name      = "ZITADEL_APPLICATION_KEY"
      valueFrom = var.zitadel_application_key_secret_arn
    },
    {
      name      = "FRESHDESK_API_KEY"
      valueFrom = var.freshdesk_api_key_secret_arn
    }
  ]
}

module "api_ecs" {
  source = "github.com/cds-snc/terraform-modules//ecs?ref=f11e70a097b0796e661b7e209e29f7d6b62240cf" # v9.6.3

  create_cluster = false
  cluster_name   = var.ecs_cluster_name
  service_name   = "forms-api"
  task_cpu       = 1024
  task_memory    = 2048

  # This causes the service to always use the latest ACTIVE task definition.
  # This gives precedence to the `cds-snc/forms-api` repo's CI/CD task deployments
  # and prevents the Terraform from undoing deployments.
  service_use_latest_task_def = true

  # Scaling
  enable_autoscaling       = true
  desired_count            = 1
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 3

  # Task definition
  container_image                     = "${var.api_image_ecr_url}:${var.api_image_tag}"
  container_host_port                 = 3001
  container_port                      = 3001
  container_environment               = local.container_env
  container_secrets                   = local.container_secrets
  container_read_only_root_filesystem = false # TODO: mount tmp filesystem for yarn cache and logs

  task_role_policy_documents = [
    data.aws_iam_policy_document.api_ecs_kms_vault.json,
    data.aws_iam_policy_document.api_ecs_dynamodb_vault.json,
    data.aws_iam_policy_document.api_ecs_s3_vault.json
  ]

  task_exec_role_policy_documents = [
    data.aws_iam_policy_document.api_ecs_secrets_manager.json
  ]

  # Networking
  lb_target_group_arn = var.lb_target_group_arn_api_ecs
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.security_group_id_api_ecs]

  billing_tag_key   = var.billing_tag_key
  billing_tag_value = var.billing_tag_value
}

#
# IAM policies
#
data "aws_iam_policy_document" "api_ecs_dynamodb_vault" {
  statement {
    sid    = "DynamoDBVault"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:BatchGetItem",
      "dynamodb:Query",
    ]

    resources = [
      var.dynamodb_vault_arn,
      "${var.dynamodb_vault_arn}/index/*"
    ]
  }
}

data "aws_iam_policy_document" "api_ecs_kms_vault" {
  statement {
    sid    = "KMSVault"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Encrypt",
      "kms:Decrypt"
    ]
    resources = [
      var.kms_key_dynamodb_arn
    ]
  }
}

data "aws_iam_policy_document" "api_ecs_s3_vault" {
  statement {
    sid    = "S3Vault"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging"
    ]
    resources = [
      var.s3_vault_file_storage_arn,
      "${var.s3_vault_file_storage_arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "api_ecs_secrets_manager" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      var.zitadel_application_key_secret_arn
    ]
  }
}
