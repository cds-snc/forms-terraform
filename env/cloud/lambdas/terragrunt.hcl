terraform {
  source = "../../../aws//lambdas"
}

include {
  path = find_in_parent_folders()
}


dependencies {
  paths = ["../rds", "../sqs", "../sns", "../kms", "../dynamodb", "../secrets", "../app", "../s3"]
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
    ecs_iam_role_arn = null
  }
}

dependency "rds" {
  enabled                                 = local.env == "local" ? false : true
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
    dynamodb_relability_queue_arn = null
    dynamodb_vault_arn            = null
    dynamodb_vault_table_name     = null
    dynamodb_vault_stream_arn     = null
    dynamodb_audit_logs_arn       = null
  }
}

dependency "secrets" {
  config_path                             = "../secrets"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    notify_api_key_secret_arn               = null
    freshdesk_api_key_secret_arn            = null
    token_secret_arn                        = null
    recaptcha_secret_arn                    = null
    notify_callback_bearer_token_secret_arn = null
  }
}

dependency "s3" {
  config_path                             = "../s3"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    reliability_file_storage_arn = null
    vault_file_storage_arn       = null
    vault_file_storage_id        = "placeholder"
    archive_storage_arn          = null
    archive_storage_id           = "placeholder"
    lambda_code_arn              = null
    lambda_code_id               = "placeholder"
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

  notify_api_key_secret_arn = dependency.secrets.outputs.notify_api_key_secret_arn

  reliability_file_storage_arn = dependency.s3.outputs.reliability_file_storage_arn
  vault_file_storage_arn       = dependency.s3.outputs.vault_file_storage_arn
  vault_file_storage_id        = dependency.s3.outputs.vault_file_storage_id
  archive_storage_arn          = dependency.s3.outputs.archive_storage_arn
  archive_storage_id           = dependency.s3.outputs.archive_storage_id
  lambda_code_arn              = dependency.s3.outputs.lambda_code_arn
  lambda_code_id               = dependency.s3.outputs.lambda_code_id

  ecs_iam_role_arn = local.env == "local" ? "arn:aws:iam:ca-central-1:000000000000:forms_iam" : dependency.app.outputs.ecs_iam_role_arn



  localstack_hosted = local.env == "local" ? true : false

  # Overwritten in GitHub Actions by TFVARS
  gc_template_id = "8d597a1b-a1d6-4e3c-8421-042a2b4158b7" # GC Notify template ID used for local setup
}

generate "import_existing_cloudwatch_logs" {
  disable     = local.env == "local"
  path      = "import.tf"
  if_exists = "overwrite"
  contents  = <<EOF
import {
  to = aws_cloudwatch_log_group.archive_form_templates
  id = "/aws/lambda/ArchiveFormTemplates"
}

import {
  to = aws_cloudwatch_log_group.audit_logs
  id = "/aws/lambda/AuditLogs"
}

import {
  to = aws_cloudwatch_log_group.dead_letter_queue_consumer
  id = "/aws/lambda/DeadLetterQueueConsumer"
}

import {
  to = aws_cloudwatch_log_group.nagware
  id = "/aws/lambda/Nagware"
}

import {
  to = aws_cloudwatch_log_group.reliability
  id = "/aws/lambda/Reliability"
}

import {
  to = aws_cloudwatch_log_group.submission
  id = "/aws/lambda/Submission"
}

import {
  to = aws_cloudwatch_log_group.vault_integrity
  id = "/aws/lambda/VaultDataIntegrityCheck"
}

import {
  to = aws_cloudwatch_log_group.response_archiver
  id = "/aws/lambda/Archiver"
}
EOF
}