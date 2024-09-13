terraform {
  source = "../../../aws//alarms"
}

dependencies {
  paths = ["../hosted_zone", "../kms", "../load_balancer", "../rds", "../sqs", "../app", "../sns", "../lambdas", "../ecr", "../api", "../idp", "../dynamodb", "../network"]
}

locals {
  domain           = jsondecode(get_env("APP_DOMAINS", "[\"localhost:3000\"]"))
  feature_flag_api = get_env("FF_API", "false")
  feature_flag_idp = get_env("FF_IDP", "false")
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
    kms_key_dynamodb_arn           = null
  }
}

dependency "load_balancer" {
  config_path = "../load_balancer"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    lb_arn                         = null
    lb_arn_suffix                  = null
    lb_target_group_1_arn_suffix   = null
    lb_target_group_2_arn_suffix   = null
    lb_target_group_api_arn_suffix = null
  }
}

dependency "rds" {
  config_path = "../rds"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    rds_cluster_identifier = "forms-mock-db-cluster"
    rds_cluster_endpoint   = "localhost"
    rds_db_name            = "default"
  }
}

dependency "sqs" {
  config_path = "../sqs"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    sqs_reliability_deadletter_queue_arn   = null
    sqs_app_audit_log_deadletter_queue_arn = null
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

dependency "api" {
  enabled                                 = local.feature_flag_api
  config_path                             = "../api"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    ecs_api_cloudwatch_log_group_name = "/aws/ecs/Forms/forms-api"
    ecs_api_cluster_name              = "Forms"
    ecs_api_service_name              = "forms-api"
  }
}

dependency "idp" {
  enabled                                 = local.feature_flag_idp
  config_path                             = "../idp"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    ecs_idp_cluster_name              = "idp"
    ecs_idp_cloudwatch_log_group_name = "/aws/ecs/idp/zitadel"
    ecs_idp_service_name              = "zitadel"
    lb_idp_arn_suffix                 = "loadbalancer/app/idp/1234567890123456"
    lb_idp_target_groups_arn_suffix = {
      HTTP1 = "targetgroup/idp-tg-http1-abc/1234567890123456"
      HTTP2 = "targetgroup/idp-tg-http2-abc/1234567890123456"
    }
    rds_idp_cluster_identifier = "idp-cluster"
  }
}

dependency "dynamodb" {
  config_path = "../dynamodb"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    dynamodb_app_audit_logs_arn = "arn:aws:dynamodb:ca-central-1:123456789012:table/AuditLogs"
  }
}

dependency "network" {
  config_path                             = "../network"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    private_subnet_ids          = [""]
    connector_security_group_id = null
  }
}

inputs = {
  threshold_ecs_cpu_utilization_high    = "50"
  threshold_ecs_memory_utilization_high = "50"
  threshold_lb_response_time            = "1"

  hosted_zone_ids = dependency.hosted_zone.outputs.hosted_zone_ids

  kms_key_cloudwatch_arn         = dependency.kms.outputs.kms_key_cloudwatch_arn
  kms_key_cloudwatch_us_east_arn = dependency.kms.outputs.kms_key_cloudwatch_us_east_arn

  lb_arn                         = dependency.load_balancer.outputs.lb_arn
  lb_arn_suffix                  = dependency.load_balancer.outputs.lb_arn_suffix
  lb_api_arn_suffix              = dependency.load_balancer.outputs.lb_arn_suffix
  lb_target_group_1_arn_suffix   = dependency.load_balancer.outputs.lb_target_group_1_arn_suffix
  lb_target_group_2_arn_suffix   = dependency.load_balancer.outputs.lb_target_group_2_arn_suffix
  lb_api_target_group_arn_suffix = dependency.load_balancer.outputs.lb_target_group_api_arn_suffix

  sqs_reliability_deadletter_queue_arn   = dependency.sqs.outputs.sqs_reliability_deadletter_queue_arn
  sqs_app_audit_log_deadletter_queue_arn = dependency.sqs.outputs.sqs_app_audit_log_deadletter_queue_arn

  ecs_cloudwatch_log_group_name = dependency.app.outputs.ecs_cloudwatch_log_group_name
  ecs_cluster_name              = dependency.app.outputs.ecs_cluster_name
  ecs_service_name              = dependency.app.outputs.ecs_service_name

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

  ecs_api_cluster_name              = local.feature_flag_api == "true" ? dependency.api.outputs.ecs_api_cluster_name : ""
  ecs_api_cloudwatch_log_group_name = local.feature_flag_api == "true" ? dependency.api.outputs.ecs_api_cloudwatch_log_group_name : ""
  ecs_api_service_name              = local.feature_flag_api == "true" ? dependency.api.outputs.ecs_api_service_name : ""

  ecs_idp_cluster_name              = local.feature_flag_idp == "true" ? dependency.idp.outputs.ecs_idp_cluster_name : ""
  ecs_idp_cloudwatch_log_group_name = local.feature_flag_idp == "true" ? dependency.idp.outputs.ecs_idp_cloudwatch_log_group_name : ""
  ecs_idp_service_name              = local.feature_flag_idp == "true" ? dependency.idp.outputs.ecs_idp_service_name : ""
  lb_idp_arn_suffix                 = local.feature_flag_idp == "true" ? dependency.idp.outputs.lb_idp_arn_suffix : ""
  lb_idp_target_groups_arn_suffix   = local.feature_flag_idp == "true" ? dependency.idp.outputs.lb_idp_target_groups_arn_suffix : {}
  rds_idp_cluster_identifier        = local.feature_flag_idp == "true" ? dependency.idp.outputs.rds_idp_cluster_identifier : ""
  rds_idp_cpu_maxiumum              = 80

  dynamodb_app_audit_logs_arn = dependency.dynamodb.outputs.dynamodb_app_audit_logs_arn
  kms_key_dynamodb_arn        = dependency.kms.outputs.kms_key_dynamodb_arn

  private_subnet_ids          = dependency.network.outputs.private_subnet_ids
  connector_security_group_id = dependency.network.outputs.connector_security_group_id
  rds_cluster_endpoint        = dependency.rds.outputs.rds_cluster_endpoint
  rds_db_name                 = dependency.rds.outputs.rds_db_name

}

include {
  path = find_in_parent_folders()
}
