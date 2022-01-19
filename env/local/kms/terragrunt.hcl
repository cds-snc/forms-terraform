terraform {
  source = "../../../aws//kms"
}

include {
  path = find_in_parent_folders()
}

remote_state {
  backend = "local"
  generate = {
    if_exists = "overwrite_terragrunt"
    path = "../../terraform.tfstate"
  }
  config = {
    path = "../../terraform.tfstate"
  }
}
