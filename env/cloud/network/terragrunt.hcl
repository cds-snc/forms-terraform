terraform {
  source = "../../../aws//network"
}

inputs = {
  vpc_cidr_block = "172.16.0.0/16"
  vpc_name       = "forms"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}
