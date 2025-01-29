terraform {
  source = "../../../aws//redis"
}

dependencies {
  paths = ["../network"]
}

dependency "network" {
  config_path                             = "../network"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    private_subnet_ids      = ["prv-1", "prv-2"]
    redis_security_group_id = "sg-1234567890"
  }
}

inputs = {
  private_subnet_ids      = dependency.network.outputs.private_subnet_ids
  redis_security_group_id = dependency.network.outputs.redis_security_group_id
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}