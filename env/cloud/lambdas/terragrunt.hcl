terraform {
  source = "../../../aws//lambdas"
}

include {
  path = find_in_parent_folders()
}


dependencies {
  paths = ["../rds","../sqs","../sns","../kms","../dynamodb","../secrets"]
}

locals {
  env = get_env("APP_ENV", "local")
}

dependency "rds" {
  enabled = local.env == "local" ? false : true
  config_path = "../rds"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    rds_cluster_arn         = ""
    rds_db_name             = ""
    database_secret_arn     = ""
  }
}

dependency "sqs" {
  config_path = "../sqs"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    sqs_reliability_queue_arn            = ""
    sqs_reliability_queue_id             = ""
    sqs_reprocess_submission_queue_arn   = ""
    sqs_reliability_dead_letter_queue_id = ""
    sqs_audit_log_queue_arn              = ""
  }
}

dependency "sns" {
  config_path = "../sns"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    sns_topic_alert_critical_arn = ""
  }
}

dependency "kms" {
  config_path = "../kms"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    kms_key_cloudwatch_arn = ""
  }
}

dependency "dynamodb" {
  config_path = "../dynamodb"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    dynamodb_vault_arn             = ""
    dynamodb_vault_table_name      = ""
  }
}

dependency "secrets" {
  config_path = "../secrets"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    notify_api_key_secret = ""
    freshdesk_api_key_secret = ""
    token_secret = ""
    recaptcha_secret = ""
    notify_callback_bearer_token_secret = ""
  }
}

inputs = {
  dynamodb_vault_arn             = dependency.dynamodb.outputs.dynamodb_vault_arn
  dynamodb_vault_table_name      = dependency.dynamodb.outputs.dynamodb_vault_table_name

  kms_key_cloudwatch_arn = dependency.kms.outputs.kms_key_cloudwatch_arn

  rds_cluster_arn         = local.env == "local" ? null : dependency.rds.outputs.rds_cluster_arn
  rds_db_name             = local.env == "local" ? null : dependency.rds.outputs.rds_db_name
  database_secret_arn     = local.env == "local" ? null : dependency.rds.outputs.database_secret_arn

  sqs_reliability_queue_arn            = dependency.sqs.outputs.sqs_reliability_queue_arn
  sqs_reliability_queue_id             = dependency.sqs.outputs.sqs_reliability_queue_id
  sqs_reprocess_submission_queue_arn   = dependency.sqs.outputs.sqs_reprocess_submission_queue_arn
  sqs_reliability_dead_letter_queue_id = dependency.sqs.outputs.sqs_reliability_dead_letter_queue_id
  sqs_audit_log_queue_arn              = dependency.sqs.outputs.sqs_audit_log_queue_arn

  sns_topic_alert_critical_arn = dependency.sns.outputs.sns_topic_alert_critical_arn
}