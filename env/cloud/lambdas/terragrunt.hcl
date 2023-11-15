terraform {
  source = "../../../aws//lambdas"
}

include {
  path = find_in_parent_folders()
}


dependencies {
  paths = ["../rds", "../sqs", "../sns", "../kms", "../dynamodb", "../secrets", "../app"]
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
    ecs_iam_role_arn = ""
  }
}

dependency "rds" {
  enabled                                 = local.env == "local" ? false : true
  config_path                             = "../rds"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    rds_cluster_arn     = ""
    rds_db_name         = ""
    database_secret_arn = ""
  }
}

dependency "sqs" {
  config_path                             = "../sqs"
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
  config_path                             = "../kms"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    kms_key_cloudwatch_arn = ""
    kms_key_dynamodb_arn   = ""
  }
}

dependency "dynamodb" {
  config_path = "../dynamodb"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    dynamodb_relability_queue_arn = ""
    dynamodb_vault_arn            = ""
    dynamodb_vault_table_name     = ""
    dynamodb_vault_stream_arn     = ""
    dynamodb_audit_logs_arn       = ""
  }
}

dependency "secrets" {
  config_path                             = "../secrets"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    notify_api_key_secret               = ""
    freshdesk_api_key_secret            = ""
    token_secret                        = ""
    recaptcha_secret                    = ""
    notify_callback_bearer_token_secret = ""
  }
}

inputs = {
  dynamodb_relability_queue_arn = dependency.dynamodb.outputs.dynamodb_relability_queue_arn
  dynamodb_vault_arn            = dependency.dynamodb.outputs.dynamodb_vault_arn
  dynamodb_vault_table_name     = dependency.dynamodb.outputs.dynamodb_vault_table_name
  dynamodb_vault_stream_arn     = dependency.dynamodb.outputs.dynamodb_vault_stream_arn
  dynamodb_audit_logs_arn       = dependency.dynamodb.outputs.dynamodb_audit_logs_arn

  kms_key_cloudwatch_arn = dependency.kms.outputs.kms_key_cloudwatch_arn
  kms_key_dynamodb_arn   = dependency.kms.outputs.kms_key_dynamodb_arn

  rds_cluster_arn     = local.env == "local" ? null : dependency.rds.outputs.rds_cluster_arn
  rds_db_name         = local.env == "local" ? null : dependency.rds.outputs.rds_db_name
  database_secret_arn = local.env == "local" ? "arn:aws:secretsmanager:ca-central-1:000000000000:secret:database_secret-VvMslX" : dependency.rds.outputs.database_secret_arn

  sqs_reliability_queue_arn            = dependency.sqs.outputs.sqs_reliability_queue_arn
  sqs_reliability_queue_id             = dependency.sqs.outputs.sqs_reliability_queue_id
  sqs_reprocess_submission_queue_arn   = dependency.sqs.outputs.sqs_reprocess_submission_queue_arn
  sqs_reliability_dead_letter_queue_id = dependency.sqs.outputs.sqs_reliability_dead_letter_queue_id
  sqs_audit_log_queue_arn              = dependency.sqs.outputs.sqs_audit_log_queue_arn

  sns_topic_alert_critical_arn = dependency.sns.outputs.sns_topic_alert_critical_arn

  notify_api_key_secret = dependency.secrets.outputs.notify_api_key_secret
  token_secret          = dependency.secrets.outputs.token_secret

  ecs_iam_role_arn = local.env == "local" ? "arn:aws:iam:ca-central-1:000000000000:forms_iam" : dependency.app.outputs.ecs_iam_role_arn

  localstack_hosted = local.env == "local" ? true : false

  # Overwritten in GitHub Actions by TFVARS
  gc_template_id = "8d597a1b-a1d6-4e3c-8421-042a2b4158b7" # GC Notify template ID used for local setup
}