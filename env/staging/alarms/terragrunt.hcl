terraform {
  source = "../../../aws//alarms"
}

dependencies {
  paths = ["../hosted_zone", "../kms", "../load_balancer", "../sqs", "../app"]
}

dependency "hosted_zone" {
  config_path = "../hosted_zone"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    hosted_zone_id = ""
  }
}

dependency "kms" {
  config_path = "../kms"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    kms_key_cloudwatch_arn = ""
  }
}

dependency "load_balancer" {
  config_path = "../load_balancer"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    lb_arn        = ""
    lb_arn_suffix = ""
  }
}

dependency "sqs" {
  config_path = "../sqs"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    sqs_deadletter_queue_arn = ""
  }
}

dependency "app" {
  config_path = "../app"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    ecs_cloudwatch_log_group_name = ""
    ecs_cluster_name              = ""
    ecs_service_name              = "" 
  }
}

inputs = {
  threshold_ecs_cpu_utilization_high    = "50"
  threshold_ecs_memory_utilization_high = "50"
  threshold_lb_response_time            = "1"

  hosted_zone_id = dependency.hosted_zone.outputs.hosted_zone_id

  kms_key_cloudwatch_arn = dependency.kms.outputs.kms_key_cloudwatch_arn

  lb_arn        = dependency.load_balancer.outputs.lb_arn
  lb_arn_suffix = dependency.load_balancer.outputs.lb_arn_suffix

  sqs_deadletter_queue_arn = dependency.sqs.outputs.sqs_deadletter_queue_arn

  ecs_cloudwatch_log_group_name = dependency.app.outputs.ecs_cloudwatch_log_group_name
  ecs_cluster_name              = dependency.app.outputs.ecs_cluster_name
  ecs_service_name              = dependency.app.outputs.ecs_service_name
}

include {
  path = find_in_parent_folders()
}