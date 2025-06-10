terraform {
  source = "../../../aws//pr_review"
}

dependencies {
  paths = ["../network", "../lambdas"]
}

dependency "lambdas" {
  config_path = "../lambdas"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_with_state           = true
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    forms_lambda_client_iam_role_name = "forms-lambda-client"
  }
}

dependency "network" {
  config_path = "../network"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_with_state           = true
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    vpc_id                        = null
    privatelink_security_group_id = "sg-1234567890"
    rds_security_group_id         = "sg-1234567890"
    redis_security_group_id       = "sg-1234567890"
    idp_ecs_security_group_id     = "sg-ecs"
  }
}

inputs = {
  forms_lambda_client_iam_role_name = dependency.lambdas.outputs.forms_lambda_client_iam_role_name

  vpc_id                           = dependency.network.outputs.vpc_id
  privatelink_security_group_id    = dependency.network.outputs.privatelink_security_group_id
  forms_database_security_group_id = dependency.network.outputs.rds_security_group_id
  forms_redis_security_group_id    = dependency.network.outputs.redis_security_group_id
  idp_ecs_security_group_id        = dependency.network.outputs.idp_ecs_security_group_id
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}