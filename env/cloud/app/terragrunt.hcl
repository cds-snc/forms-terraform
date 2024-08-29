terraform {
  source = "../../../aws//app"
}

dependencies {
  paths = ["../kms", "../network", "../dynamodb", "../rds", "../redis", "../sqs", "../load_balancer", "../ecr", "../cognito", "../secrets", "../s3"]
}

dependency "dynamodb" {
  config_path = "../dynamodb"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    dynamodb_relability_queue_arn = null
    dynamodb_vault_arn            = null
  }
}

dependency "ecr" {
  config_path = "../ecr"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    ecr_repository_url_form_viewer = null
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

dependency "load_balancer" {
  config_path                             = "../load_balancer"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    lb_https_listener_arn  = null
    lb_target_group_1_arn  = null
    lb_target_group_1_name = null
    lb_target_group_2_name = null
  }
}

dependency "network" {
  config_path                             = "../network"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    private_subnet_ids = [""]
  }
}

dependency "rds" {
  config_path                             = "../rds"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    database_url_secret_arn = null
  }
}

dependency "redis" {
  config_path                             = "../redis"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    redis_url = null
  }
}

dependency "sqs" {
  config_path                             = "../sqs"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    sqs_reprocess_submission_queue_arn = null
    sqs_audit_log_queue_arn            = null
    sqs_audit_log_queue_id             = null
    sqs_reprocess_submission_queue_id  = null
  }
}

dependency "cognito" {
  config_path = "../cognito"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    cognito_endpoint_url  = null
    cognito_client_id     = null
    cognito_user_pool_arn = null
  }
}

dependency "secrets" {
  config_path                             = "../secrets"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    notify_api_key_secret_arn               = "arn:aws:secretsmanager:ca-central-1:123456789012:secret:notify_api_key"
    freshdesk_api_key_secret_arn            = "arn:aws:secretsmanager:ca-central-1:123456789012:secret:freshdesk_api_key_secret"
    token_secret_arn                        = "arn:aws:secretsmanager:ca-central-1:123456789012:secret:token_secret"
    recaptcha_secret_arn                    = "arn:aws:secretsmanager:ca-central-1:123456789012:secret:recaptcha_secret"
    notify_callback_bearer_token_secret_arn = "arn:aws:secretsmanager:ca-central-1:123456789012:secret:notify_callback_bearer_token_secret"
    zitadel_administration_key_secret_arn   = "arn:aws:secretsmanager:ca-central-1:123456789012:secret:zitadel_administration_key"
  }
}

dependency "s3" {
  config_path                             = "../s3"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    vault_file_storage_id        = "forms-staging-vault-file-storage"
    vault_file_storage_arn       = "arn:aws:s3:::forms-staging-vault-file-storage"
    reliability_file_storage_id  = "forms-staging-reliability-file-storage"
    reliability_file_storage_arn = "arn:aws:s3:::forms-staging-reliability-file-storage"
  }
}

locals {
  zitadel_provider                            = get_env("ZITADEL_PROVIDER", "https://localhost")
}

inputs = {
  codedeploy_manual_deploy_enabled            = false
  codedeploy_termination_wait_time_in_minutes = 1
  ecs_autoscale_enabled                       = true
  ecs_form_viewer_name                        = "form-viewer"
  ecs_name                                    = "Forms"
  ecs_min_tasks                               = 2
  ecs_max_tasks                               = 3
  ecs_scale_cpu_threshold                     = 25
  ecs_scale_memory_threshold                  = 15
  ecs_scale_in_cooldown                       = 60
  ecs_scale_out_cooldown                      = 60
  metric_provider                             = "stdout"
  tracer_provider                             = "stdout"

  dynamodb_relability_queue_arn = dependency.dynamodb.outputs.dynamodb_relability_queue_arn
  dynamodb_vault_arn            = dependency.dynamodb.outputs.dynamodb_vault_arn

  ecr_repository_url_form_viewer = dependency.ecr.outputs.ecr_repository_url_form_viewer

  kms_key_cloudwatch_arn = dependency.kms.outputs.kms_key_cloudwatch_arn
  kms_key_dynamodb_arn   = dependency.kms.outputs.kms_key_dynamodb_arn

  lb_https_listener_arn  = dependency.load_balancer.outputs.lb_https_listener_arn
  lb_target_group_1_arn  = dependency.load_balancer.outputs.lb_target_group_1_arn
  lb_target_group_1_name = dependency.load_balancer.outputs.lb_target_group_1_name
  lb_target_group_2_name = dependency.load_balancer.outputs.lb_target_group_2_name

  ecs_security_group_id    = dependency.network.outputs.ecs_security_group_id
  egress_security_group_id = dependency.network.outputs.egress_security_group_id
  private_subnet_ids       = dependency.network.outputs.private_subnet_ids

  redis_url = dependency.redis.outputs.redis_url

  database_url_secret_arn = dependency.rds.outputs.database_url_secret_arn

  sqs_reprocess_submission_queue_arn = dependency.sqs.outputs.sqs_reprocess_submission_queue_arn
  sqs_audit_log_queue_arn            = dependency.sqs.outputs.sqs_audit_log_queue_arn
  sqs_audit_log_queue_id             = dependency.sqs.outputs.sqs_audit_log_queue_id
  sqs_reprocess_submission_queue_id  = dependency.sqs.outputs.sqs_reprocess_submission_queue_id

  cognito_endpoint_url  = dependency.cognito.outputs.cognito_endpoint_url
  cognito_client_id     = dependency.cognito.outputs.cognito_client_id
  cognito_user_pool_arn = dependency.cognito.outputs.cognito_user_pool_arn

  recaptcha_secret_arn                    = dependency.secrets.outputs.recaptcha_secret_arn
  notify_api_key_secret_arn               = dependency.secrets.outputs.notify_api_key_secret_arn
  freshdesk_api_key_secret_arn            = dependency.secrets.outputs.freshdesk_api_key_secret_arn
  notify_callback_bearer_token_secret_arn = dependency.secrets.outputs.notify_callback_bearer_token_secret_arn
  token_secret_arn                        = dependency.secrets.outputs.token_secret_arn
  zitadel_administration_key_secret_arn   = dependency.secrets.outputs.zitadel_administration_key_secret_arn

  vault_file_storage_arn = dependency.s3.outputs.vault_file_storage_arn
  vault_file_storage_id = dependency.s3.outputs.vault_file_storage_id
  reliability_file_storage_arn = dependency.s3.outputs.reliability_file_storage_arn
  reliability_file_storage_id = dependency.s3.outputs.reliability_file_storage_id

  zitadel_provider = local.zitadel_provider

  # Address Complete is completed on the client browser side.
  addresscomplete_api_key                = "UR78-BU29-RU35-EP49" # Key is domain locked, and presented to the client.
}

include {
  path = find_in_parent_folders()
}
