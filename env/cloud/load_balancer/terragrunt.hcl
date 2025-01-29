terraform {
  source = "../../../aws//load_balancer"
}

dependencies {
  paths = ["../hosted_zone", "../network"]
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

dependency "network" {
  config_path                             = "../network"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    alb_security_group_id = null
    public_subnet_ids     = [""]
    vpc_id                = null
  }
}

inputs = {
  hosted_zone_ids       = dependency.hosted_zone.outputs.hosted_zone_ids
  alb_security_group_id = dependency.network.outputs.alb_security_group_id
  public_subnet_ids     = dependency.network.outputs.public_subnet_ids
  vpc_id                = dependency.network.outputs.vpc_id
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}
