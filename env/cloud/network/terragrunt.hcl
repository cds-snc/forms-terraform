terraform {
  source = "../../../aws//network"
}

dependencies {
  paths = ["../kms"]
}

dependency "kms" {
  config_path                             = "../kms"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    kms_key_cloudwatch_arn = null
  }
}


locals {
  env = get_env("APP_ENV", "development")
}


inputs = {
  vpc_cidr_block         = "172.16.0.0/16"
  vpc_name               = "forms"
  kms_key_cloudwatch_arn = dependency.kms.outputs.kms_key_cloudwatch_arn
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

generate "network" {
  path      = "network.tf"
  if_exists = "overwrite"
  contents  = local.env == "development" ? file("../../../aws/network/.development_env/network.tf") : local.env == "staging" ? file("../../../aws/network/.staging_env/network.tf") : file("../../../aws/network/network.tf")
}

generate "firewall" {
  path      = "firewall.tf"
  if_exists = "overwrite"
  contents  = local.env == "staging" ? file("../../../aws/network/firewall.tf") : file("../../../aws/network/.development_env/firewall.tf")
}

generate "vpc_endpoints" {
  path      = "vpc_endpoints.tf"
  if_exists = "overwrite"
  contents  = local.env == "development" ? file("../../../aws/network/.development_env/vpc_endpoints.tf") : file("../../../aws/network/vpc_endpoints.tf")
}

