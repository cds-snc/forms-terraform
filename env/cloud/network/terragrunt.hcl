terraform {
  source = "../../../aws//network"
}

locals {
  env = get_env("APP_ENV", "development")
}


inputs = {
  vpc_cidr_block = "172.16.0.0/16"
  vpc_name       = "forms"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

generate "network" {
  path      = "network.tf"
  if_exists = "overwrite"
  contents  = local.env == "development" ? file("../../../aws/network/development_env/network_dev.tf") : file("../../../aws/network/network.tf")
}

generate "vpc_endpoints" {
  path      = "vpc_endpoints.tf"
  if_exists = "overwrite"
  contents  = local.env == "development" ? file("../../../local_dev_files/tf/blank.tf") : file("../../../aws/network/vpc_endpoints.tf")
}
