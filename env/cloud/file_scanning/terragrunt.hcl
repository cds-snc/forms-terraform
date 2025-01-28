terraform {
  source = "../../../aws//file_scanning"
}

dependencies {
  paths = ["../s3"]
}

dependency "s3" {
  config_path                             = "../s3"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    vault_file_storage_id = "forms-staging-vault-file-storage"
  }
}

inputs = {
  vault_file_storage_id = dependency.s3.outputs.vault_file_storage_id
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}