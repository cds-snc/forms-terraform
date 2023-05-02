terraform {
  source = "../../../aws//app"
}

dependencies {
  paths = ["../kms", "../network", "../dynamodb", "../rds", "../redis", "../sqs", "../load_balancer", "../ecr", "../sns", "../cognito"]
}

dependency "dynamodb" {
  config_path = "../dynamodb"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_with_state  = true
  mock_outputs = {
    dynamodb_relability_queue_arn  = ""
    dynamodb_vault_arn             = ""
    dynamodb_vault_table_name      = ""
    dynamodb_audit_logs_arn        = ""
    dynamodb_audit_logs_table_name = ""
  }
}

dependency "ecr" {
  config_path = "../ecr"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_with_state  = true
  mock_outputs = {
    ecr_repository_url_form_viewer = ""
  }
}

dependency "kms" {
  config_path = "../kms"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    kms_key_cloudwatch_arn = ""
    kms_key_dynamodb_arn   = ""
  }
}

dependency "load_balancer" {
  config_path = "../load_balancer"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    lb_https_listener_arn  = ""
    lb_target_group_1_arn  = ""
    lb_target_group_1_name = ""
    lb_target_group_2_name = ""
  }
}

dependency "network" {
  config_path = "../network"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    private_subnet_ids = [""]
  }
}

dependency "rds" {
  config_path = "../rds"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    rds_cluster_arn         = ""
    rds_db_name             = ""
    database_url_secret_arn = ""
    database_secret_arn     = ""
  }
}

dependency "redis" {
  config_path = "../redis"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    redis_url = ""
  }
}

dependency "sqs" {
  config_path = "../sqs"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_with_state           = true
  mock_outputs = {
    sqs_reliability_queue_arn            = ""
    sqs_reliability_queue_id             = ""
    sqs_reprocess_submission_queue_arn   = ""
    sqs_reliability_dead_letter_queue_id = ""
    sqs_audit_log_queue_arn              = ""
    sqs_audit_log_queue_id               = ""
    sqs_audit_log_deadletter_queue_arn   = ""
    sqs_reprocess_submission_queue_id    = ""
  }
}

dependency "sns" {
  config_path = "../sns"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_with_state           = true
  mock_outputs = {
    sns_topic_alert_critical_arn = ""
    sns_topic_alert_warning_arn  = ""
    sns_topic_alert_ok_arn       = ""
  }
}

dependency "cognito" {
  config_path = "../cognito"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_with_state           = true
  mock_outputs = {
    cognito_endpoint_url  = ""
    cognito_client_id     = ""
    cognito_user_pool_arn = ""
  }
}

inputs = {
  codedeploy_manual_deploy_enabled            = false
  codedeploy_termination_wait_time_in_minutes = 1
  ecs_autoscale_enabled                       = true
  ecs_form_viewer_name                        = "form-viewer"
  ecs_name                                    = "Forms"
  ecs_min_tasks                               = 1
  ecs_max_tasks                               = 2
  ecs_scale_cpu_threshold                     = 60
  ecs_scale_memory_threshold                  = 60
  ecs_scale_in_cooldown                       = 60
  ecs_scale_out_cooldown                      = 60
  metric_provider                             = "stdout"
  tracer_provider                             = "stdout"

  dynamodb_relability_queue_arn  = dependency.dynamodb.outputs.dynamodb_relability_queue_arn
  dynamodb_vault_arn             = dependency.dynamodb.outputs.dynamodb_vault_arn
  dynamodb_vault_table_name      = dependency.dynamodb.outputs.dynamodb_vault_table_name
  dynamodb_audit_logs_arn        = dependency.dynamodb.outputs.dynamodb_audit_logs_arn
  dynamodb_audit_logs_table_name = dependency.dynamodb.outputs.dynamodb_audit_logs_table_name

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

  rds_cluster_arn         = dependency.rds.outputs.rds_cluster_arn
  rds_db_name             = dependency.rds.outputs.rds_db_name
  database_secret_arn     = dependency.rds.outputs.database_secret_arn
  database_url_secret_arn = dependency.rds.outputs.database_url_secret_arn

  sqs_reliability_queue_arn            = dependency.sqs.outputs.sqs_reliability_queue_arn
  sqs_reliability_queue_id             = dependency.sqs.outputs.sqs_reliability_queue_id
  sqs_reprocess_submission_queue_arn   = dependency.sqs.outputs.sqs_reprocess_submission_queue_arn
  sqs_reliability_dead_letter_queue_id = dependency.sqs.outputs.sqs_reliability_dead_letter_queue_id
  sqs_audit_log_queue_arn              = dependency.sqs.outputs.sqs_audit_log_queue_arn
  sqs_audit_log_queue_id               = dependency.sqs.outputs.sqs_audit_log_queue_id
  sqs_audit_log_deadletter_queue_arn   = dependency.sqs.outputs.sqs_audit_log_deadletter_queue_arn
  sqs_reprocess_submission_queue_id    = dependency.sqs.outputs.sqs_reprocess_submission_queue_id

  sns_topic_alert_critical_arn = dependency.sns.outputs.sns_topic_alert_critical_arn
  sns_topic_alert_warning_arn  = dependency.sns.outputs.sns_topic_alert_warning_arn
  sns_topic_alert_ok_arn       = dependency.sns.outputs.sns_topic_alert_ok_arn

  cognito_endpoint_url  = dependency.cognito.outputs.cognito_endpoint_url
  cognito_client_id     = dependency.cognito.outputs.cognito_client_id
  cognito_user_pool_arn = dependency.cognito.outputs.cognito_user_pool_arn

}

include {
  path = find_in_parent_folders()
}
