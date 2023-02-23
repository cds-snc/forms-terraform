terraform {
  source = "../../../aws//app"
  extra_arguments "target_s3" {
    commands = [
      "plan",
      "apply"
    ]

    arguments = [
      "-target=aws_s3_bucket.reliability_file_storage",
      "-target=aws_s3_bucket_public_access_block.reliability_file_storage",
      "-target=aws_s3_bucket.vault_file_storage",
      "-target=aws_s3_bucket_public_access_block.vault_file_storage",
      "-target=aws_s3_bucket.archive_storage",
      "-target=aws_s3_bucket_public_access_block.archive_storage",
    ]
  }
}

dependencies {
  paths = ["../kms", "../dynamodb", "../sqs"]
}

dependency "dynamodb" {
  config_path = "../dynamodb"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    dynamodb_relability_queue_arn = ""
    dynamodb_vault_arn            = ""
    dynamodb_vault_table_name     = ""
    dynamodb_vault_stream_arn     = ""
  }
}

dependency "sqs" {
  config_path = "../sqs"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    sqs_reliability_queue_arn          = ""
    sqs_reliability_queue_id           = ""
    sqs_reprocess_submission_queue_arn = ""
    sqs_dead_letter_queue_id           = ""
    sqs_audit_log_queue_arn            = ""
    sqs_audit_log_queue_id             = ""
    sqs_audit_log_deadletter_queue_arn = ""
    sqs_reprocess_submission_queue_id  = ""
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
  ecs_secret_token_secret                     = "local"
  google_client_id                            = "local"
  google_client_secret                        = "local"
  recaptcha_secret                            = "local"
  recaptcha_public                            = "local"
  notify_api_key                              = "local"
  rds_db_password                             = "local"
  slack_webhook                               = "local"
  gc_notify_callback_bearer_token             = "local"

  sns_topic_alert_critical_arn = ""
  sns_topic_alert_warning_arn  = ""
  sns_topic_alert_ok_arn       = ""

  dynamodb_relability_queue_arn  = dependency.dynamodb.outputs.dynamodb_relability_queue_arn
  dynamodb_vault_arn             = dependency.dynamodb.outputs.dynamodb_vault_arn
  dynamodb_vault_table_name      = dependency.dynamodb.outputs.dynamodb_vault_table_name
  dynamodb_vault_stream_arn      = dependency.dynamodb.outputs.dynamodb_vault_stream_arn
  dynamodb_audit_logs_arn        = dependency.dynamodb.outputs.dynamodb_audit_logs_arn
  dynamodb_audit_logs_table_name = dependency.dynamodb.outputs.dynamodb_audit_logs_table_name

  ecr_repository_url = ""

  kms_key_cloudwatch_arn = dependency.kms.outputs.kms_key_cloudwatch_arn
  kms_key_dynamodb_arn   = dependency.kms.outputs.kms_key_dynamodb_arn

  lb_https_listener_arn  = ""
  lb_target_group_1_arn  = ""
  lb_target_group_1_name = ""
  lb_target_group_2_name = ""

  ecs_security_group_id    = ""
  egress_security_group_id = ""
  private_subnet_ids       = ["42342"]

  redis_url = ""

  rds_cluster_arn         = ""
  rds_db_name             = ""
  database_secret_arn     = ""
  database_url_secret_arn = ""

  sqs_reliability_queue_arn          = dependency.sqs.outputs.sqs_reliability_queue_arn
  sqs_reliability_queue_id           = dependency.sqs.outputs.sqs_reliability_queue_id
  sqs_reprocess_submission_queue_arn = dependency.sqs.outputs.sqs_reprocess_submission_queue_arn
  sqs_dead_letter_queue_id           = dependency.sqs.outputs.sqs_dead_letter_queue_id
  sqs_audit_log_queue_arn            = dependency.sqs.outputs.sqs_audit_log_queue_arn
  sqs_audit_log_queue_id             = dependency.sqs.outputs.sqs_audit_log_queue_id
  sqs_audit_log_deadletter_queue_arn = dependency.sqs.outputs.sqs_audit_log_deadletter_queue_arn
  sqs_reprocess_submission_queue_id  = dependency.sqs.outputs.sqs_reprocess_submission_queue_id

  gc_temp_token_template_id = "b6885d06-d10a-422a-973f-05e274d9aa86"
  gc_template_id            = "8d597a1b-a1d6-4e3c-8421-042a2b4158b7"

}

remote_state {
  backend = "local"
  generate = {
    if_exists = "overwrite_terragrunt"
    path      = "../../terraform.tfstate"
  }
  config = {
    path = "../../terraform.tfstate"
  }
}


include {
  path = find_in_parent_folders()
}
