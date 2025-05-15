terraform {
  source = "../../../aws//api"
}

dependencies {
  paths = ["../kms", "../network", "../dynamodb", "../load_balancer", "../ecr", "../redis", "../s3", "../app", "../secrets", "../rds", "../sqs", "../idp"]
}

dependency "app" {
  config_path = "../app"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    ecs_cluster_name = "Forms"
  }
}

dependency "dynamodb" {
  config_path = "../dynamodb"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    dynamodb_vault_arn = "arn:aws:dynamodb:ca-central-1:${local.aws_account_id}:table/Vault"
  }
}

dependency "ecr" {
  config_path = "../ecr"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    ecr_repository_url_api = "${local.aws_account_id}.dkr.ecr.ca-central-1.amazonaws.com/forms/api"
  }
}

dependency "kms" {
  config_path                             = "../kms"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    kms_key_dynamodb_arn = "arn:aws:kms:ca-central-1:${local.aws_account_id}:key/12345678-796a-461b-9f69-b0e0c40f5d0a"
  }
}

dependency "load_balancer" {
  config_path                             = "../load_balancer"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    lb_target_group_api_arn = "arn:aws:elasticloadbalancing:ca-central-1:${local.aws_account_id}:targetgroup/forms-api/1234567890abcdef"
  }
}

dependency "network" {
  config_path                             = "../network"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    api_ecs_security_group_id                              = "sg-1234567890"
    private_subnet_ids                                     = ["prv-1", "prv-2"]
    service_discovery_private_dns_namespace_ecs_local_id   = ""
    service_discovery_private_dns_namespace_ecs_local_name = "ecs.local"
  }
}

dependency "redis" {
  config_path                             = "../redis"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    redis_port = 6379
    redis_url  = "mock-redis-url.0001.cache.amazonaws.com"
  }
}

dependency "s3" {
  config_path                             = "../s3"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    vault_file_storage_arn = "arn:aws:s3:::forms-mock-vault-file-storage"
  }
}

dependency "secrets" {
  config_path                             = "../secrets"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    zitadel_application_key_secret_arn = "arn:aws:secretsmanager:ca-central-1:${local.aws_account_id}:secret:zitadel_application_key"
    freshdesk_api_key_secret_arn       = "arn:aws:secretsmanager:ca-central-1:${local.aws_account_id}:secret:freshdesk_api_key_secret"
  }
}

dependency "rds" {
  config_path                             = "../rds"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    database_url_secret_arn = "arn:aws:secretsmanager:ca-central-1:${local.aws_account_id}:secret:database_url"
  }
}

dependency "sqs" {
  config_path                             = "../sqs"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    sqs_api_audit_log_queue_arn = "arn:aws:sqs:ca-central-1:${local.aws_account_id}:api_audit_log_queue"
  }
}

dependency "idp" {
  enabled = local.env != "development"

  config_path = "../idp"

  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    ecs_idp_service_name = "zitadel"
    ecs_idp_service_port = 8080
  }
}

locals {
  zitadel_domain = get_env("ZITADEL_PROVIDER", "https://localhost")
  aws_account_id = get_env("AWS_ACCOUNT_ID", "000000000000")
}

inputs = {
  api_image_tag               = "latest"
  api_image_ecr_url           = dependency.ecr.outputs.ecr_repository_url_api
  ecs_cluster_name            = dependency.app.outputs.ecs_cluster_name
  lb_target_group_arn_api_ecs = dependency.load_balancer.outputs.lb_target_group_api_arn

  security_group_id_api_ecs                              = dependency.network.outputs.api_ecs_security_group_id
  private_subnet_ids                                     = dependency.network.outputs.private_subnet_ids
  service_discovery_private_dns_namespace_ecs_local_id   = dependency.network.outputs.service_discovery_private_dns_namespace_ecs_local_id
  service_discovery_private_dns_namespace_ecs_local_name = dependency.network.outputs.service_discovery_private_dns_namespace_ecs_local_name

  kms_key_dynamodb_arn      = dependency.kms.outputs.kms_key_dynamodb_arn
  dynamodb_vault_arn        = dependency.dynamodb.outputs.dynamodb_vault_arn
  s3_vault_file_storage_arn = dependency.s3.outputs.vault_file_storage_arn

  redis_port = dependency.redis.outputs.redis_port
  redis_url  = dependency.redis.outputs.redis_url

  zitadel_domain                     = local.zitadel_domain
  zitadel_application_key_secret_arn = dependency.secrets.outputs.zitadel_application_key_secret_arn

  freshdesk_api_key_secret_arn = dependency.secrets.outputs.freshdesk_api_key_secret_arn

  rds_connection_url_secret_arn = dependency.rds.outputs.database_url_secret_arn

  sqs_api_audit_log_queue_arn = dependency.sqs.outputs.sqs_api_audit_log_queue_arn

  ecs_idp_service_name = dependency.idp.outputs.ecs_idp_service_name
  ecs_idp_service_port = dependency.idp.outputs.ecs_idp_service_port
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}
