terraform {
  source = "../../../aws//alarms"
}

dependencies {
  paths = ["../hosted_zone", "../kms", "../load_balancer", "../rds", "../sqs", "../app", "../sns", "../lambdas", "../ecr"]
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
    lb_target_group_1_arn_suffix = null
    lb_target_group_2_arn_suffix = null
  }
}

dependency "rds" {
  config_path = "../rds"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    rds_cluster_identifier = "forms-mock-db-cluster"
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
    lambda_audit_logs_log_group_name               = "/aws/lambda/Audit_Logs"
    lambda_audit_logs_archiver_log_group_name      = "/aws/lambda/Audit_Logs_Archiver"
    lambda_form_archiver_function_name             = "form-archiver"
    lambda_form_archiver_log_group_name            = "/aws/lambda/Archive_Form_Templates"
    lambda_nagware_function_name                   = "nagware"
    lambda_nagware_log_group_name                  = "/aws/lambda/Nagware"
    lambda_reliability_log_group_name              = "/aws/lambda/Reliability"
    lambda_reliability_dlq_consumer_log_group_name = "/aws/lambda/Reliability_DLQ_Consumer"
    lambda_response_archiver_function_name         = "response-archiver"
    lambda_response_archiver_log_group_name        = "/aws/lambda/Response_Archiver"
    lambda_submission_function_name                = "Submission"
    lambda_submission_log_group_name               = "/aws/lambda/Submission"
    lambda_vault_integrity_log_group_name          = "/aws/lambda/Vault_Data_Integrity_Check"
    lambda_vault_integrity_function_name           = "vault-integrity"
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

dependency "ecr" {
  config_path                             = "../ecr"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    ecr_repository_url_notify_slack_lambda = ""
  }
}

inputs = {
  threshold_ecs_cpu_utilization_high    = "50"
  threshold_ecs_memory_utilization_high = "50"
  threshold_lb_response_time            = "1"

  hosted_zone_ids = dependency.hosted_zone.outputs.hosted_zone_ids

  kms_key_cloudwatch_arn         = dependency.kms.outputs.kms_key_cloudwatch_arn
  kms_key_cloudwatch_us_east_arn = dependency.kms.outputs.kms_key_cloudwatch_us_east_arn

  lb_arn                        = dependency.load_balancer.outputs.lb_arn
  lb_arn_suffix                 = dependency.load_balancer.outputs.lb_arn_suffix
  lb_target_group_1_arn_suffix  = dependency.load_balancer.outputs.lb_target_group_1_arn_suffix
  lb_target_group_2_arn_suffix  = dependency.load_balancer.outputs.lb_target_group_2_arn_suffix

  sqs_reliability_deadletter_queue_arn = dependency.sqs.outputs.sqs_reliability_deadletter_queue_arn
  sqs_audit_log_deadletter_queue_arn   = dependency.sqs.outputs.sqs_audit_log_deadletter_queue_arn

  ecs_cloudwatch_log_group_name                    = dependency.app.outputs.ecs_cloudwatch_log_group_name
  ecs_cluster_name                                 = dependency.app.outputs.ecs_cluster_name
  ecs_service_name                                 = dependency.app.outputs.ecs_service_name

  lambda_audit_logs_log_group_name               = dependency.lambdas.outputs.lambda_audit_logs_log_group_name
  lambda_audit_logs_archiver_log_group_name      = dependency.lambdas.outputs.lambda_audit_logs_archiver_log_group_name
  lambda_form_archiver_function_name             = dependency.lambdas.outputs.lambda_form_archiver_function_name
  lambda_form_archiver_log_group_name            = dependency.lambdas.outputs.lambda_form_archiver_log_group_name
  lambda_nagware_function_name                   = dependency.lambdas.outputs.lambda_nagware_function_name
  lambda_nagware_log_group_name                  = dependency.lambdas.outputs.lambda_nagware_log_group_name
  lambda_reliability_log_group_name              = dependency.lambdas.outputs.lambda_reliability_log_group_name
  lambda_reliability_dlq_consumer_log_group_name = dependency.lambdas.outputs.lambda_reliability_dlq_consumer_log_group_name
  lambda_response_archiver_function_name         = dependency.lambdas.outputs.lambda_response_archiver_function_name
  lambda_response_archiver_log_group_name        = dependency.lambdas.outputs.lambda_response_archiver_log_group_name
  lambda_submission_expect_invocation_in_period  = 30
  lambda_submission_function_name                = dependency.lambdas.outputs.lambda_submission_function_name
  lambda_submission_log_group_name               = dependency.lambdas.outputs.lambda_submission_log_group_name
  lambda_vault_integrity_log_group_name          = dependency.lambdas.outputs.lambda_vault_integrity_log_group_name
  lambda_vault_integrity_function_name           = dependency.lambdas.outputs.lambda_vault_integrity_function_name

  rds_cluster_identifier = dependency.rds.outputs.rds_cluster_identifier

  sns_topic_alert_critical_arn        = dependency.sns.outputs.sns_topic_alert_critical_arn
  sns_topic_alert_warning_arn         = dependency.sns.outputs.sns_topic_alert_warning_arn
  sns_topic_alert_ok_arn              = dependency.sns.outputs.sns_topic_alert_ok_arn
  sns_topic_alert_warning_us_east_arn = dependency.sns.outputs.sns_topic_alert_warning_us_east_arn
  sns_topic_alert_ok_us_east_arn      = dependency.sns.outputs.sns_topic_alert_ok_us_east_arn

  ecr_repository_url_notify_slack_lambda = dependency.ecr.outputs.ecr_repository_url_notify_slack_lambda
}

include {
  path = find_in_parent_folders()
}
