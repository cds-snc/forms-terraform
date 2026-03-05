terraform {
  source = "../../../aws//backup"
}

dependencies {
  paths = ["../dynamodb", "../rds", "../s3"]
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}



