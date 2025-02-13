terraform {
  source = "../../../aws//ecr"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  // overwritten by TFVars
  aws_development_accounts = ["123456789012"]
  cds_org_id               = ["o-1234567890"]
}