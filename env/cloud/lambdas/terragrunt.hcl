terraform {
  source = "../../../aws//lambdas"
}

include {
  path = find_in_parent_folders()
}


dependencies {
  paths = ["../rds", "../sqs", "../sns", "../kms", "../dynamodb", "../secrets", "../app", "../s3", "../ecr"]
}

locals {
  env = get_env("APP_ENV", "local")
}

dependency "app" {
  enabled                                 = local.env == "local" ? false : true
  config_path                             = "../app"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    ecs_iam_role_arn = "arn:aws:iam::123456789012:role/form-viewer"
  }
}

dependency "rds" {
  config_path                             = "../rds"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    rds_cluster_arn     = null
    rds_db_name         = null
    database_secret_arn = null
  }
}

dependency "sqs" {
  config_path                             = "../sqs"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    sqs_reliability_queue_arn            = null
    sqs_reliability_queue_id             = null
    sqs_reprocess_submission_queue_arn   = null
    sqs_reliability_dead_letter_queue_id = null
    sqs_audit_log_queue_arn              = null
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
  config_path                             = "../kms"
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
    dynamodb_relability_queue_arn  = "arn:aws:dynamodb:ca-central-1:123456789012:table/ReliabilityQueue"
    dynamodb_vault_arn             = "arn:aws:dynamodb:ca-central-1:123456789012:table/Vault"
    dynamodb_vault_table_name      = "Vault"
    dynamodb_vault_stream_arn      = "arn:aws:dynamodb:ca-central-1:123456789012:table/Vault/stream/2023-03-14T15:54:31.086"
    dynamodb_audit_logs_table_name = "AuditLogs"
    dynamodb_audit_logs_arn        = "arn:aws:dynamodb:ca-central-1:123456789012:table/AuditLogs"
  }
}

dependency "secrets" {
  config_path                             = "../secrets"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    notify_api_key_secret_arn               = "arn:aws:secretsmanager:ca-central-1:123456789012:secret:notify_api_key"
    freshdesk_api_key_secret_arn            = "arn:aws:secretsmanager:ca-central-1:123456789012:secret:freshdesk_api_key_secret"
    token_secret_arn                        = "arn:aws:secretsmanager:ca-central-1:123456789012:secret:token_secret"
    recaptcha_secret_arn                    = "arn:aws:secretsmanager:ca-central-1:123456789012:secret:recaptcha_secret"
    notify_callback_bearer_token_secret_arn = "arn:aws:secretsmanager:ca-central-1:123456789012:secret:notify_callback_bearer_token_secret"
  }
}

dependency "s3" {
  config_path                             = "../s3"
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
  }
}

dependency "ecr" {
  config_path                             = "../ecr"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    ecr_repository_url_audit_logs_lambda               = ""
    ecr_repository_url_audit_logs_archiver_lambda      = ""
    ecr_repository_url_form_archiver_lambda            = ""
    ecr_repository_url_nagware_lambda                  = ""
    ecr_repository_url_reliability_lambda              = ""
    ecr_repository_url_reliability_dlq_consumer_lambda = ""
    ecr_repository_url_response_archiver_lambda        = ""
    ecr_repository_url_submission_lambda               = ""
    ecr_repository_url_vault_integrity_lambda          = ""
  }
}

inputs = {
  dynamodb_relability_queue_arn  = dependency.dynamodb.outputs.dynamodb_relability_queue_arn
  dynamodb_vault_arn             = dependency.dynamodb.outputs.dynamodb_vault_arn
  dynamodb_vault_table_name      = dependency.dynamodb.outputs.dynamodb_vault_table_name
  dynamodb_vault_stream_arn      = dependency.dynamodb.outputs.dynamodb_vault_stream_arn
  dynamodb_audit_logs_table_name = dependency.dynamodb.outputs.dynamodb_audit_logs_table_name
  dynamodb_audit_logs_arn        = dependency.dynamodb.outputs.dynamodb_audit_logs_arn

  kms_key_cloudwatch_arn = dependency.kms.outputs.kms_key_cloudwatch_arn
  kms_key_dynamodb_arn   = dependency.kms.outputs.kms_key_dynamodb_arn

  rds_cluster_arn     = dependency.rds.outputs.rds_cluster_arn
  rds_db_name         = dependency.rds.outputs.rds_db_name
  database_secret_arn = dependency.rds.outputs.database_secret_arn

  sqs_reliability_queue_arn            = dependency.sqs.outputs.sqs_reliability_queue_arn
  sqs_reliability_queue_id             = dependency.sqs.outputs.sqs_reliability_queue_id
  sqs_reprocess_submission_queue_arn   = dependency.sqs.outputs.sqs_reprocess_submission_queue_arn
  sqs_reliability_dead_letter_queue_id = dependency.sqs.outputs.sqs_reliability_dead_letter_queue_id
  sqs_audit_log_queue_arn              = dependency.sqs.outputs.sqs_audit_log_queue_arn

  sns_topic_alert_critical_arn = dependency.sns.outputs.sns_topic_alert_critical_arn

  notify_api_key_secret_arn = dependency.secrets.outputs.notify_api_key_secret_arn

  reliability_file_storage_arn   = dependency.s3.outputs.reliability_file_storage_arn
  vault_file_storage_arn         = dependency.s3.outputs.vault_file_storage_arn
  vault_file_storage_id          = dependency.s3.outputs.vault_file_storage_id
  archive_storage_arn            = dependency.s3.outputs.archive_storage_arn
  archive_storage_id             = dependency.s3.outputs.archive_storage_id
  audit_logs_archive_storage_id  = dependency.s3.outputs.audit_logs_archive_storage_id
  audit_logs_archive_storage_arn = dependency.s3.outputs.audit_logs_archive_storage_arn

  ecr_repository_url_audit_logs_lambda               = dependency.ecr.outputs.ecr_repository_url_audit_logs_lambda
  ecr_repository_url_audit_logs_archiver_lambda      = dependency.ecr.outputs.ecr_repository_url_audit_logs_archiver_lambda
  ecr_repository_url_form_archiver_lambda            = dependency.ecr.outputs.ecr_repository_url_form_archiver_lambda
  ecr_repository_url_nagware_lambda                  = dependency.ecr.outputs.ecr_repository_url_nagware_lambda
  ecr_repository_url_reliability_lambda              = dependency.ecr.outputs.ecr_repository_url_reliability_lambda
  ecr_repository_url_reliability_dlq_consumer_lambda = dependency.ecr.outputs.ecr_repository_url_reliability_dlq_consumer_lambda
  ecr_repository_url_response_archiver_lambda        = dependency.ecr.outputs.ecr_repository_url_response_archiver_lambda
  ecr_repository_url_submission_lambda               = dependency.ecr.outputs.ecr_repository_url_submission_lambda
  ecr_repository_url_vault_integrity_lambda          = dependency.ecr.outputs.ecr_repository_url_vault_integrity_lambda

  ecs_iam_role_arn = local.env == "local" ? "arn:aws:iam:ca-central-1:000000000000:forms_iam" : dependency.app.outputs.ecs_iam_role_arn

  localstack_hosted = local.env == "local" ? true : false

  # Overwritten in GitHub Actions by TFVARS
  gc_template_id = "8d597a1b-a1d6-4e3c-8421-042a2b4158b7" # GC Notify template ID used for local setup
}