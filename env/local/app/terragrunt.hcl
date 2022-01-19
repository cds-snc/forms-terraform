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
  paths = ["../kms",  "../dynamodb" ]
}

dependency "dynamodb" {
  config_path = "../dynamodb"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    dynamodb_relability_queue_arn = ""
    dynamodb_vault_arn            = ""
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
  notify_api_key                              = "local"
  rds_db_password                             = "local"
  slack_webhook                               = "local"

  dynamodb_relability_queue_arn = dependency.dynamodb.outputs.dynamodb_relability_queue_arn
  dynamodb_vault_arn            = dependency.dynamodb.outputs.dynamodb_vault_arn
  sns_topic_alert_critical_arn  = ""

  dynamodb_vault_retrieved_index_name = dependency.dynamodb.outputs.dynamodb_vault_retrieved_index_name
  dynamodb_vault_table_name = dependency.dynamodb.outputs.dynamodb_vault_table_name

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

  rds_cluster_arn            = ""
  rds_db_name                = ""
  database_secret_arn        = ""
  database_url_secret_arn    = ""

  sqs_reliability_queue_arn = ""
  sqs_reliability_queue_id  = ""
}

include {
  path = find_in_parent_folders()
}
