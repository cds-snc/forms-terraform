terraform {
  source = "../../../aws//dynamodb"
}

dependencies {
  paths = ["../kms"]
}

dependency "kms" {
  config_path = "../kms"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    kms_key_dynamodb_arn = ""
  }
}

inputs = {
  kms_key_dynamodb_arn = dependency.kms.outputs.kms_key_dynamodb_arn
  env = "local"
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

include {
  path = find_in_parent_folders()
}
