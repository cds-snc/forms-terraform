terraform {
  source = "../../../aws//alarms"
}

dependencies {
  paths = ["../hosted_zone", "../kms", "../load_balancer", "../rds", "../sqs", "../app", "../sns", "../lambdas", "../ecr", "../api", "../idp", "../dynamodb", "../network"]
}

locals {
  domain         = jsondecode(get_env("APP_DOMAINS", "[\"localhost:3000\"]"))
  aws_account_id = get_env("AWS_ACCOUNT_ID", "000000000000")
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
    lb_arn                                            = null
    lb_arn_suffix                                     = null
    lb_target_group_1_arn_suffix                      = null
    lb_target_group_2_arn_suffix                      = null
    lb_target_group_api_arn_suffix                    = null
    waf_ipv4_new_blocked_ip_metric_filter_name        = "default"
    waf_ipv4_new_blocked_ip_metric_filter_namespace   = "default"
    unhealthy_host_count_for_target_group_1_alarm_arn = ""
    unhealthy_host_count_for_target_group_2_alarm_arn = ""
  }
}

dependency "rds" {
  config_path = "../rds"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    rds_cluster_identifier      = "forms-mock-db-cluster"
    rds_cluster_reader_endpoint = "localhost"
    rds_db_name                 = "default"
  }
}

dependency "sqs" {
  config_path = "../sqs"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    sqs_reliability_deadletter_queue_name   = "reliability_deadletter_queue"
    sqs_app_audit_log_deadletter_queue_name = "audit_log_deadletter_queue"
    sqs_api_audit_log_deadletter_queue_name = "api_audit_log_deadletter_queue"
    sqs_file_upload_deadletter_queue_name   = "file_upload_deadletter_queue"
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
    lambda_api_end_to_end_test_log_group_name      = "/aws/lambda/API_End_To_End_Test"
    lambda_file_upload_processor_log_group_name    = "/aws/lambda/file-upload-processor"
    lambda_file_upload_cleanup_log_group_name      = "/aws/lambda/file-upload-cleanup"
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
    dynamodb_app_audit_logs_arn = "arn:aws:dynamodb:ca-central-1:${local.aws_account_id}:table/AuditLogs"
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

  lb_arn                                            = dependency.load_balancer.outputs.lb_arn
  lb_arn_suffix                                     = dependency.load_balancer.outputs.lb_arn_suffix
  lb_api_arn_suffix                                 = dependency.load_balancer.outputs.lb_arn_suffix
  lb_target_group_1_arn_suffix                      = dependency.load_balancer.outputs.lb_target_group_1_arn_suffix
  lb_target_group_2_arn_suffix                      = dependency.load_balancer.outputs.lb_target_group_2_arn_suffix
  lb_api_target_group_arn_suffix                    = dependency.load_balancer.outputs.lb_target_group_api_arn_suffix
  waf_ipv4_new_blocked_ip_metric_filter_name        = dependency.load_balancer.outputs.waf_ipv4_new_blocked_ip_metric_filter_name
  waf_ipv4_new_blocked_ip_metric_filter_namespace   = dependency.load_balancer.outputs.waf_ipv4_new_blocked_ip_metric_filter_namespace
  unhealthy_host_count_for_target_group_1_alarm_arn = dependency.load_balancer.outputs.unhealthy_host_count_for_target_group_1_alarm_arn
  unhealthy_host_count_for_target_group_2_alarm_arn = dependency.load_balancer.outputs.unhealthy_host_count_for_target_group_2_alarm_arn

  sqs_reliability_deadletter_queue_name   = dependency.sqs.outputs.sqs_reliability_deadletter_queue_name
  sqs_app_audit_log_deadletter_queue_name = dependency.sqs.outputs.sqs_app_audit_log_deadletter_queue_name
  sqs_api_audit_log_deadletter_queue_name = dependency.sqs.outputs.sqs_api_audit_log_deadletter_queue_name
  sqs_file_upload_deadletter_queue_name   = dependency.sqs.outputs.sqs_file_upload_deadletter_queue_name

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
  lambda_api_end_to_end_test_log_group_name      = dependency.lambdas.outputs.lambda_api_end_to_end_test_log_group_name
  lambda_file_upload_processor_log_group_name    = dependency.lambdas.outputs.lambda_file_upload_processor_log_group_name
  lambda_file_upload_cleanup_log_group_name      = dependency.lambdas.outputs.lambda_file_upload_cleanup_log_group_name

  rds_cluster_identifier = dependency.rds.outputs.rds_cluster_identifier

  sns_topic_alert_critical_arn        = dependency.sns.outputs.sns_topic_alert_critical_arn
  sns_topic_alert_warning_arn         = dependency.sns.outputs.sns_topic_alert_warning_arn
  sns_topic_alert_ok_arn              = dependency.sns.outputs.sns_topic_alert_ok_arn
  sns_topic_alert_warning_us_east_arn = dependency.sns.outputs.sns_topic_alert_warning_us_east_arn
  sns_topic_alert_ok_us_east_arn      = dependency.sns.outputs.sns_topic_alert_ok_us_east_arn

  ecr_repository_url_notify_slack_lambda = dependency.ecr.outputs.ecr_repository_url_notify_slack_lambda

  ecs_api_cluster_name              = dependency.api.outputs.ecs_api_cluster_name
  ecs_api_cloudwatch_log_group_name = dependency.api.outputs.ecs_api_cloudwatch_log_group_name
  ecs_api_service_name              = dependency.api.outputs.ecs_api_service_name

  ecs_idp_cluster_name              = dependency.idp.outputs.ecs_idp_cluster_name
  ecs_idp_cloudwatch_log_group_name = dependency.idp.outputs.ecs_idp_cloudwatch_log_group_name
  ecs_idp_service_name              = dependency.idp.outputs.ecs_idp_service_name
  lb_idp_arn_suffix                 = dependency.idp.outputs.lb_idp_arn_suffix
  lb_idp_target_groups_arn_suffix   = dependency.idp.outputs.lb_idp_target_groups_arn_suffix
  rds_idp_cluster_identifier        = dependency.idp.outputs.rds_idp_cluster_identifier
  rds_idp_cpu_maxiumum              = 80

  dynamodb_app_audit_logs_arn = dependency.dynamodb.outputs.dynamodb_app_audit_logs_arn
  kms_key_dynamodb_arn        = dependency.kms.outputs.kms_key_dynamodb_arn

  private_subnet_ids          = dependency.network.outputs.private_subnet_ids
  connector_security_group_id = dependency.network.outputs.connector_security_group_id
  rds_cluster_reader_endpoint = dependency.rds.outputs.rds_cluster_reader_endpoint
  rds_db_name                 = dependency.rds.outputs.rds_db_name

}

include "root" {
  path = find_in_parent_folders("root.hcl")
}
