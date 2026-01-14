locals {
  container_env = [
    {
      name  = "ZITADEL_URL"
      value = "http://${var.ecs_idp_service_name}.${var.service_discovery_private_dns_namespace_ecs_local_name}:${var.ecs_idp_service_port}"
    },
    {
      name  = "ZITADEL_TRUSTED_DOMAIN"
      value = "auth.${var.domains[0]}"
    },
    {
      name  = "ENVIRONMENT_MODE"
      value = var.env
    },
    {
      name  = "REDIS_URL"
      value = "redis://${var.redis_url}:${var.redis_port}"
    },
    {
      name  = "VAULT_FILE_STORAGE_BUCKET_NAME"
      value = var.vault_file_storage_id
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
  source = "github.com/cds-snc/terraform-modules//ecs?ref=825c15a16d794bd878e0d11555c0abe6f481f29e" # v10.10.2

  create_cluster = false
  cluster_name   = var.ecs_cluster_name
  service_name   = "forms-api"
  task_cpu       = 2048
  task_memory    = 4096

  # This causes the service to always use the latest ACTIVE task definition.
  # This gives precedence to the `cds-snc/forms-api` repo's CI/CD task deployments
  # and prevents the Terraform from undoing deployments.
  service_use_latest_task_def = true

  # Scaling
  enable_autoscaling       = true
  desired_count            = 2
  autoscaling_min_capacity = 2
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
    data.aws_iam_policy_document.api_ecs_s3_vault.json,
    data.aws_iam_policy_document.api_ecs_secrets_manager_runtime.json,
    data.aws_iam_policy_document.api_sqs.json
  ]

  task_exec_role_policy_documents = [
    data.aws_iam_policy_document.api_ecs_secrets_manager.json
  ]

  # Networking
  lb_target_group_arn            = var.lb_target_group_arn_api_ecs
  subnet_ids                     = var.private_subnet_ids
  security_group_ids             = [var.security_group_id_api_ecs]
  service_discovery_enabled      = true
  service_discovery_namespace_id = var.service_discovery_private_dns_namespace_ecs_local_id

  # Logging
  cloudwatch_log_group_retention_in_days = 731

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
      "dynamodb:Scan",
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

data "aws_iam_policy_document" "api_ecs_secrets_manager_runtime" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      var.rds_connection_url_secret_arn
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
      var.zitadel_application_key_secret_arn,
      var.freshdesk_api_key_secret_arn
    ]
  }
}
data "aws_iam_policy_document" "api_sqs" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:GetQueueUrl",
      "sqs:SendMessage"
    ]

    resources = [
      var.sqs_api_audit_log_queue_arn
    ]
  }
}
