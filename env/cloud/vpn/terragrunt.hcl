terraform {
  source = "../../../aws//vpn"
}

dependencies {
  paths = ["../network"]
}

dependency "network" {
  config_path                             = "../network"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    private_subnet_ids    = [""]
    ecs_security_group_id = null
    vpc_id                = null
  }
}

inputs = {
  private_subnet_ids    = dependency.network.outputs.private_subnet_ids
  ecs_security_group_id = dependency.network.outputs.ecs_security_group_id
  vpc_id                = dependency.network.outputs.vpc_id
  # non dynamic
  vpc_cidr_block = "172.16.0.0/16"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}