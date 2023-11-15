terraform {
  source = "../../../aws//file_scanning"
}

include {
  path = find_in_parent_folders()
}


dependencies {
  paths = ["../lambdas"]
}

dependency "lambdas" {
  config_path                             = "../lambdas"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    vault_file_storage_id = ""
  }
}

inputs = {
  vault_file_storage_id = dependency.lambdas.outputs.vault_file_storage_id
}

