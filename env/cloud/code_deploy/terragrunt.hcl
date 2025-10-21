terraform {
  source = "../../../aws//code_deploy"
}

dependencies {
  paths = ["../rds","../network"]
}


dependency "network" {
  config_path                             = "../network"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    private_subnet_ids          = [""]
    vpc_id                      = "vpc-id"
    code_build_security_group_id = "1234"
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

inputs = { 
  private_subnet_ids           = dependency.network.outputs.private_subnet_ids
  vpc_id                       = dependency.network.outputs.vpc_id
  code_build_security_group_id = dependency.network.outputs.code_build_security_group_id
  database_url_secret_arn      = dependency.rds.outputs.database_url_secret_arn
 }

include "root" {
  path = find_in_parent_folders("root.hcl")
}
