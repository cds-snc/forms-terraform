terraform {
  source = "../../../aws//lambdas"
}

dependencies {
  paths = ["../network", "../rds", "../redis", "../sqs", "../sns", "../kms", "../dynamodb", "../secrets", "../app", "../s3", "../ecr", "../idp", "../api"]
}

locals {
  env            = get_env("APP_ENV", "development")
  aws_account_id = get_env("AWS_ACCOUNT_ID", "000000000000")
}

dependency "app" {
  enabled = local.env != "development"

  config_path = "../app"

  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    ecs_iam_role_arn                         = "arn:aws:iam::${local.aws_account_id}:role/form-viewer"
    ecs_iam_forms_secrets_manager_policy_arn = null
    ecs_iam_forms_kms_policy_arn             = null
    ecs_iam_forms_s3_policy_arn              = null
    ecs_iam_forms_dynamodb_policy_arn        = null
    ecs_iam_forms_sqs_policy_arn             = null
    ecs_iam_forms_cognito_policy_arn         = null
  }
}

dependency "network" {
  config_path = "../network"

  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    lambda_security_group_id                               = "sg-1234"
    private_subnet_ids                                     = ["prv-1", "prv-2"]
    service_discovery_private_dns_namespace_ecs_local_name = "ecs.local"
    api_end_to_end_test_lambda_security_group_id           = "sg-1235"
  }
}

dependency "rds" {
  config_path = "../rds"

  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    rds_cluster_arn         = null
    rds_db_name             = null
    database_secret_arn     = null
    database_url_secret_arn = null
  }
}

dependency "redis" {
  config_path = "../redis"

  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    redis_port = 6379
    redis_url  = "mock-redis-url.0001.cache.amazonaws.com"
  }
}

dependency "sqs" {
  config_path = "../sqs"

  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    sqs_reliability_queue_arn            = "arn:aws:sqs:ca-central-1:${local.aws_account_id}:reliability_queue"
    sqs_reliability_queue_id             = "https://sqs.ca-central-1.amazonaws.com/${local.aws_account_id}/submission_processing.fifo"
    sqs_reprocess_submission_queue_arn   = "arn:aws:sqs:ca-central-1:${local.aws_account_id}:reprocess_submission_queue.fifo"
    sqs_reliability_dead_letter_queue_id = "https://sqs.ca-central-1.amazonaws.com/${local.aws_account_id}/reliability_deadletter_queue.fifo"
    sqs_app_audit_log_queue_arn          = "arn:aws:sqs:ca-central-1:${local.aws_account_id}:audit_log_queue"
    sqs_api_audit_log_queue_arn          = "arn:aws:sqs:ca-central-1:${local.aws_account_id}:api_audit_log_queue"
  }
}

dependency "sns" {
  config_path = "../sns"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    sns_topic_alert_critical_arn = null
  }
}

dependency "kms" {
  config_path = "../kms"

  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    kms_key_cloudwatch_arn = null
    kms_key_dynamodb_arn   = null
  }
}

dependency "dynamodb" {
  config_path = "../dynamodb"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    dynamodb_relability_queue_arn      = "arn:aws:dynamodb:ca-central-1:${local.aws_account_id}:table/ReliabilityQueue"
    dynamodb_vault_arn                 = "arn:aws:dynamodb:ca-central-1:${local.aws_account_id}:table/Vault"
    dynamodb_vault_table_name          = "Vault"
    dynamodb_vault_stream_arn          = "arn:aws:dynamodb:ca-central-1:${local.aws_account_id}:table/Vault/stream/2023-03-14T15:54:31.086"
    dynamodb_app_audit_logs_table_name = "AuditLogs"
    dynamodb_app_audit_logs_arn        = "arn:aws:dynamodb:ca-central-1:${local.aws_account_id}:table/AuditLogs"
    dynamodb_api_audit_logs_table_name = "ApiAuditLogs"
    dynamodb_api_audit_logs_arn        = "arn:aws:dynamodb:ca-central-1:${local.aws_account_id}:table/ApiAuditLogs"
  }
}

dependency "secrets" {
  config_path = "../secrets"

  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    notify_api_key_secret_arn               = "arn:aws:secretsmanager:ca-central-1:${local.aws_account_id}:secret:notify_api_key"
    freshdesk_api_key_secret_arn            = "arn:aws:secretsmanager:ca-central-1:${local.aws_account_id}:secret:freshdesk_api_key_secret"
    token_secret_arn                        = "arn:aws:secretsmanager:ca-central-1:${local.aws_account_id}:secret:token_secret"
    recaptcha_secret_arn                    = "arn:aws:secretsmanager:ca-central-1:${local.aws_account_id}:secret:recaptcha_secret"
    notify_callback_bearer_token_secret_arn = "arn:aws:secretsmanager:ca-central-1:${local.aws_account_id}:secret:notify_callback_bearer_token_secret"
  }
}

dependency "s3" {
  config_path = "../s3"

  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    reliability_file_storage_arn   = "arn:aws:s3:::forms-staging-reliability-file-storage"
    vault_file_storage_arn         = "arn:aws:s3:::forms-staging-vault-file-storage"
    vault_file_storage_id          = "forms-staging-vault-file-storage"
    archive_storage_arn            = "arn:aws:s3:::forms-staging-archive-storage"
    archive_storage_id             = "forms-staging-archive-storage"
    audit_logs_archive_storage_id  = "forms-staging-audit-logs-archive-storage"
    audit_logs_archive_storage_arn = "arn:aws:s3:::forms-staging-audit-logs-archive-storage"
    prisma_migration_storage_id    = "forms-staging-prisma-migration-storage"
    prisma_migration_storage_arn   = "arn:aws:s3:::forms-staging-prisma-migration-storage"
  }
}

dependency "ecr" {
  config_path = "../ecr"

  mock_outputs_merge_strategy_with_state  = "deep_map_only"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    ecr_repository_lambda_urls = {
      type                            = "map",
      audit-logs-lambda               = "test_url",
      audit-logs-archiver-lambda      = "test_url",
      cognito-email-sender-lambda     = "test_url",
      cognito-pre-sign-up-lambda      = "test_url",
      form-archiver-lambda            = "test_url",
      nagware-lambda                  = "test_url",
      notify-slack-lambda             = "test_url",
      reliability-lambda              = "test_url",
      reliability-dlq-consumer-lambda = "test_url",
      response-archiver-lambda        = "test_url",
      submission-lambda               = "test_url",
      vault-integrity-lambda          = "test_url",
      load-testing-lambda             = "test_url",
      prisma-migration-lambda         = "test_url",
      api-end-to-end-test-lambda      = "test_url"
    }
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

dependency "api" {
  enabled = local.env != "development"

  config_path = "../api"

  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    ecs_api_service_name = "forms-api"
    ecs_api_service_port = 3001
  }
}

inputs = {
  ecs_iam_role_arn                         = local.env == "development" ? null : dependency.app.outputs.ecs_iam_role_arn
  ecs_iam_forms_secrets_manager_policy_arn = dependency.app.outputs.ecs_iam_forms_secrets_manager_policy_arn
  ecs_iam_forms_kms_policy_arn             = dependency.app.outputs.ecs_iam_forms_kms_policy_arn
  ecs_iam_forms_s3_policy_arn              = dependency.app.outputs.ecs_iam_forms_s3_policy_arn
  ecs_iam_forms_dynamodb_policy_arn        = dependency.app.outputs.ecs_iam_forms_dynamodb_policy_arn
  ecs_iam_forms_sqs_policy_arn             = dependency.app.outputs.ecs_iam_forms_sqs_policy_arn
  ecs_iam_forms_cognito_policy_arn         = dependency.app.outputs.ecs_iam_forms_cognito_policy_arn

  lambda_security_group_id                               = dependency.network.outputs.lambda_security_group_id
  private_subnet_ids                                     = dependency.network.outputs.private_subnet_ids
  service_discovery_private_dns_namespace_ecs_local_name = dependency.network.outputs.service_discovery_private_dns_namespace_ecs_local_name
  api_end_to_end_test_lambda_security_group_id           = dependency.network.outputs.api_end_to_end_test_lambda_security_group_id

  dynamodb_relability_queue_arn      = dependency.dynamodb.outputs.dynamodb_relability_queue_arn
  dynamodb_vault_arn                 = dependency.dynamodb.outputs.dynamodb_vault_arn
  dynamodb_vault_table_name          = dependency.dynamodb.outputs.dynamodb_vault_table_name
  dynamodb_vault_stream_arn          = dependency.dynamodb.outputs.dynamodb_vault_stream_arn
  dynamodb_app_audit_logs_table_name = dependency.dynamodb.outputs.dynamodb_app_audit_logs_table_name
  dynamodb_app_audit_logs_arn        = dependency.dynamodb.outputs.dynamodb_app_audit_logs_arn
  dynamodb_api_audit_logs_table_name = dependency.dynamodb.outputs.dynamodb_api_audit_logs_table_name
  dynamodb_api_audit_logs_arn        = dependency.dynamodb.outputs.dynamodb_api_audit_logs_arn

  kms_key_cloudwatch_arn = dependency.kms.outputs.kms_key_cloudwatch_arn
  kms_key_dynamodb_arn   = dependency.kms.outputs.kms_key_dynamodb_arn

  rds_cluster_arn         = dependency.rds.outputs.rds_cluster_arn
  rds_db_name             = dependency.rds.outputs.rds_db_name
  database_secret_arn     = dependency.rds.outputs.database_secret_arn
  database_url_secret_arn = dependency.rds.outputs.database_url_secret_arn

  redis_port = dependency.redis.outputs.redis_port
  redis_url  = dependency.redis.outputs.redis_url

  sqs_reliability_queue_arn            = dependency.sqs.outputs.sqs_reliability_queue_arn
  sqs_reliability_queue_id             = dependency.sqs.outputs.sqs_reliability_queue_id
  sqs_reprocess_submission_queue_arn   = dependency.sqs.outputs.sqs_reprocess_submission_queue_arn
  sqs_reliability_dead_letter_queue_id = dependency.sqs.outputs.sqs_reliability_dead_letter_queue_id
  sqs_app_audit_log_queue_arn          = dependency.sqs.outputs.sqs_app_audit_log_queue_arn
  sqs_api_audit_log_queue_arn          = dependency.sqs.outputs.sqs_api_audit_log_queue_arn

  sns_topic_alert_critical_arn = dependency.sns.outputs.sns_topic_alert_critical_arn

  notify_api_key_secret_arn = dependency.secrets.outputs.notify_api_key_secret_arn

  reliability_file_storage_arn   = dependency.s3.outputs.reliability_file_storage_arn
  vault_file_storage_arn         = dependency.s3.outputs.vault_file_storage_arn
  vault_file_storage_id          = dependency.s3.outputs.vault_file_storage_id
  archive_storage_arn            = dependency.s3.outputs.archive_storage_arn
  archive_storage_id             = dependency.s3.outputs.archive_storage_id
  audit_logs_archive_storage_id  = dependency.s3.outputs.audit_logs_archive_storage_id
  audit_logs_archive_storage_arn = dependency.s3.outputs.audit_logs_archive_storage_arn
  prisma_migration_storage_id    = dependency.s3.outputs.prisma_migration_storage_id
  prisma_migration_storage_arn   = dependency.s3.outputs.prisma_migration_storage_arn

  ecr_repository_lambda_urls = dependency.ecr.outputs.ecr_repository_lambda_urls

  ecs_idp_service_name = dependency.idp.outputs.ecs_idp_service_name
  ecs_idp_service_port = dependency.idp.outputs.ecs_idp_service_port

  ecs_api_service_name = dependency.api.outputs.ecs_api_service_name
  ecs_api_service_port = dependency.api.outputs.ecs_api_service_port

  # Overwritten in GitHub Actions by TFVARS
  gc_template_id                           = "8d597a1b-a1d6-4e3c-8421-042a2b4158b7" # GC Notify template ID used for local setup
  idp_project_identifier                   = "" # IdP project identifier used by API end to end test
  api_end_to_end_test_form_identifier      = "" # Form identifier used by API end to end test
  api_end_to_end_test_form_api_private_key = "" # Form API private key used by API end to end test
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}