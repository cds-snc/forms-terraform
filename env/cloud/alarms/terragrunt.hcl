terraform {
  source = "../../../aws//alarms"
}

dependencies {
  paths = ["../hosted_zone", "../kms", "../load_balancer", "../sqs", "../app", "../sns", "../lambdas"]
}

locals {
  domain = jsondecode(get_env("APP_DOMAINS", "[\"localhost:3000\"]"))
}

dependency "hosted_zone" {
  config_path                             = "../hosted_zone"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    hosted_zone_ids = formatlist("mocked_zone_id_%s", local.domain)
  }
}

dependency "kms" {
  config_path = "../kms"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    kms_key_cloudwatch_arn         = null
    kms_key_cloudwatch_us_east_arn = null
  }
}

dependency "load_balancer" {
  config_path = "../load_balancer"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    lb_arn                = null
    lb_arn_suffix         = null
    lb_target_group_1_arn = null
    lb_target_group_2_arn = null
  }
}

dependency "sqs" {
  config_path = "../sqs"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    sqs_reliability_deadletter_queue_arn = null
    sqs_audit_log_deadletter_queue_arn   = null
  }
}

dependency "app" {
  config_path = "../app"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    ecs_cloudwatch_log_group_name = null
    ecs_cluster_name              = null
    ecs_service_name              = null
  }
}

dependency "lambdas" {
  config_path                             = "../lambdas"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    lambda_reliability_log_group_name                = "/aws/lambda/Reliability"
    lambda_submission_log_group_name                 = "/aws/lambda/Submission"
    lambda_response_archiver_log_group_name          = "/aws/lambda/Response_Archiver"
    lambda_dlq_consumer_log_group_name               = "/aws/lambda/DeadLetterQueueConsumer"
    lambda_template_archiver_log_group_name          = "/aws/lambda/Archive_Form_Templates"
    lambda_audit_log_group_name                      = "/aws/lambda/AuditLogs"
    lambda_nagware_log_group_name                    = "/aws/lambda/Nagware"
    lambda_vault_data_integrity_check_log_group_name = "/aws/lambda/Vault_Data_Integrity_Check"
    lambda_vault_data_integrity_check_function_name  = "Vault_Data_Integrity_Check"
    lambda_audit_logs_archiver_group_name            = "/aws/lambda/Audit_Logs_Archiver"
  }
}

dependency "sns" {
  config_path = "../sns"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    sns_topic_alert_critical_arn        = null
    sns_topic_alert_warning_arn         = null
    sns_topic_alert_ok_arn              = null
    sns_topic_alert_warning_us_east_arn = null
    sns_topic_alert_ok_us_east_arn      = null
  }
}

inputs = {
  threshold_ecs_cpu_utilization_high    = "50"
  threshold_ecs_memory_utilization_high = "50"
  threshold_lb_response_time            = "1"

  hosted_zone_ids = dependency.hosted_zone.outputs.hosted_zone_ids

  kms_key_cloudwatch_arn         = dependency.kms.outputs.kms_key_cloudwatch_arn
  kms_key_cloudwatch_us_east_arn = dependency.kms.outputs.kms_key_cloudwatch_us_east_arn

  lb_arn                = dependency.load_balancer.outputs.lb_arn
  lb_arn_suffix         = dependency.load_balancer.outputs.lb_arn_suffix
  lb_target_group_1_arn = dependency.load_balancer.outputs.lb_target_group_1_arn
  lb_target_group_2_arn = dependency.load_balancer.outputs.lb_target_group_2_arn

  sqs_reliability_deadletter_queue_arn = dependency.sqs.outputs.sqs_reliability_deadletter_queue_arn
  sqs_audit_log_deadletter_queue_arn   = dependency.sqs.outputs.sqs_audit_log_deadletter_queue_arn

  ecs_cloudwatch_log_group_name                    = dependency.app.outputs.ecs_cloudwatch_log_group_name
  ecs_cluster_name                                 = dependency.app.outputs.ecs_cluster_name
  ecs_service_name                                 = dependency.app.outputs.ecs_service_name
  lambda_reliability_log_group_name                = dependency.lambdas.outputs.lambda_reliability_log_group_name
  lambda_submission_log_group_name                 = dependency.lambdas.outputs.lambda_submission_log_group_name
  lambda_response_archiver_log_group_name          = dependency.lambdas.outputs.lambda_response_archiver_log_group_name
  lambda_dlq_consumer_log_group_name               = dependency.lambdas.outputs.lambda_dlq_consumer_log_group_name
  lambda_template_archiver_log_group_name          = dependency.lambdas.outputs.lambda_template_archiver_log_group_name
  lambda_audit_log_group_name                      = dependency.lambdas.outputs.lambda_audit_log_group_name
  lambda_nagware_log_group_name                    = dependency.lambdas.outputs.lambda_nagware_log_group_name
  lambda_vault_data_integrity_check_log_group_name = dependency.lambdas.outputs.lambda_vault_data_integrity_check_log_group_name
  lambda_vault_data_integrity_check_function_name  = dependency.lambdas.outputs.lambda_vault_data_integrity_check_function_name
  lambda_audit_logs_archiver_group_name            = dependency.lambdas.outputs.lambda_audit_logs_archiver_group_name

  sns_topic_alert_critical_arn        = dependency.sns.outputs.sns_topic_alert_critical_arn
  sns_topic_alert_warning_arn         = dependency.sns.outputs.sns_topic_alert_warning_arn
  sns_topic_alert_ok_arn              = dependency.sns.outputs.sns_topic_alert_ok_arn
  sns_topic_alert_warning_us_east_arn = dependency.sns.outputs.sns_topic_alert_warning_us_east_arn
  sns_topic_alert_ok_us_east_arn      = dependency.sns.outputs.sns_topic_alert_ok_us_east_arn
}

include {
  path = find_in_parent_folders()
}
