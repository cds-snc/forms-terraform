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
    ecs_iam_role_arn = "arn:aws:iam::123456789012:role/form-viewer"
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
    dynamodb_relability_queue_arn  = "arn:aws:dynamodb:ca-central-1:123456789012:table/ReliabilityQueue"
    dynamodb_vault_arn             = "arn:aws:dynamodb:ca-central-1:123456789012:table/Vault"
    dynamodb_vault_table_name      = "Vault"
    dynamodb_vault_stream_arn      = "arn:aws:dynamodb:ca-central-1:123456789012:table/Vault/stream/2023-03-14T15:54:31.086"
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
    reliability_file_storage_arn = "arn:aws:s3:::forms-staging-reliability-file-storage"
    vault_file_storage_arn       = "arn:aws:s3:::forms-staging-vault-file-storage"
    vault_file_storage_id        = "forms-staging-vault-file-storage"
    archive_storage_arn          = "arn:aws:s3:::forms-staging-archive-storage"
    archive_storage_id           = "forms-staging-archive-storage"
    lambda_code_arn              = "arn:aws:s3:::forms-staging-lambda-code"
    lambda_code_id               = "forms-staging-lambda-code"
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

generate "import_existing_resources" {
  disable     = local.env != "production"
  path      = "import.tf"
  if_exists = "overwrite"
  contents  = <<EOF
import {
  id = "iam_for_lambda"
  to = aws_iam_role.lambda
}

import {
  id = "arn:aws:iam::${local.account_id}:policy/lambda_logging"
  to = aws_iam_policy.lambda_logging
}

import {
  id = "arn:aws:iam::${local.account_id}:policy/lambda_kms"
  to = aws_iam_policy.lambda_kms
}

import {
  id = "arn:aws:iam::${local.account_id}:policy/lambda_rds"
  to = aws_iam_policy.lambda_rds
}

import {
  id = "arn:aws:iam::${local.account_id}:policy/lambda_sqs"
  to = aws_iam_policy.lambda_sqs
}

import {
  id = "arn:aws:iam::${local.account_id}:policy/lambda_dynamobdb"
  to = aws_iam_policy.lambda_dynamodb
}

import {
  id = "arn:aws:iam::${local.account_id}:policy/lambda_secrets"
  to = aws_iam_policy.lambda_secrets
}

import {
  id = "arn:aws:iam::${local.account_id}:policy/lambda_s3"
  to = aws_iam_policy.lambda_s3
}

import {
  id = "arn:aws:iam::${local.account_id}:policy/lambda_sns"
  to = aws_iam_policy.lambda_sns
}

import {
  id = "iam_for_lambda/arn:aws:iam::${local.account_id}:policy/lambda_secrets"
  to = aws_iam_role_policy_attachment.lambda_secrets
}

import {
  id = "iam_for_lambda/arn:aws:iam::${local.account_id}:policy/lambda_logging"
  to = aws_iam_role_policy_attachment.lambda_logs
}

import {
  id = "iam_for_lambda/arn:aws:iam::${local.account_id}:policy/lambda_sqs"
  to = aws_iam_role_policy_attachment.lambda_sqs
}

import {
  id = "iam_for_lambda/arn:aws:iam::${local.account_id}:policy/lambda_dynamobdb"
  to = aws_iam_role_policy_attachment.lambda_dynamodb
}

import {
  id = "iam_for_lambda/arn:aws:iam::${local.account_id}:policy/lambda_kms"
  to = aws_iam_role_policy_attachment.lambda_kms
}

import {
  id = "iam_for_lambda/arn:aws:iam::${local.account_id}:policy/lambda_rds"
  to = aws_iam_role_policy_attachment.lambda_rds
}

import {
  id = "iam_for_lambda/arn:aws:iam::${local.account_id}:policy/lambda_s3"
  to = aws_iam_role_policy_attachment.lambda_s3
}

import {
  id = "iam_for_lambda/arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  to = aws_iam_role_policy_attachment.AWSLambdaVPCAccessExecutionRole
}

import {
  id = "iam_for_lambda/arn:aws:iam::${local.account_id}:policy/lambda_sns"
  to = aws_iam_role_policy_attachment.lambda_sns
}

import {
  id = "Nagware"
  to = aws_lambda_function.nagware
}

import {
  id = "Nagware/AllowExecutionFromCloudWatch"
  to = aws_lambda_permission.allow_cloudwatch_to_run_nagware_lambda
}

import {
  id = "/aws/lambda/Nagware"
  to = aws_cloudwatch_log_group.nagware
}

import {
  id = "Reliability"
  to = aws_lambda_function.reliability
}

import {
  id = "2f994c5c-aeea-4d98-a56a-cd857e06ac89"
  to = aws_lambda_event_source_mapping.reliability
}

import {
  id = "da835a8c-6843-42f8-8509-6955dab673f1"
  to = aws_lambda_event_source_mapping.reprocess_submission
}

import {
  id = "/aws/lambda/Reliability"
  to = aws_cloudwatch_log_group.reliability
}

import {
  id = "Submission"
  to = aws_lambda_function.submission
}

import {
  id = "Submission/AllowInvokeECS"
  to = aws_lambda_permission.submission
}

import {
  id = "/aws/lambda/Submission"
  to = aws_cloudwatch_log_group.submission
}

import {
  id = "every-day-at-2am"
  to = aws_cloudwatch_event_rule.cron_2am_every_day
}

import {
  id = "every-day-at-3am"
  to = aws_cloudwatch_event_rule.cron_3am_every_day
}

import {
  id = "every-day-at-4am"
  to = aws_cloudwatch_event_rule.cron_4am_every_day
}

import {
  id = "every-business-day-at-5am"
  to = aws_cloudwatch_event_rule.cron_5am_every_business_day
}
EOF
}