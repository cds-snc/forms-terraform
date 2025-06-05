terraform {
  source = "../../../aws//guard_duty"
}

dependencies {
  paths = ["../s3" ]
}

dependency "s3" {
  config_path = "../s3"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    reliability_file_storage_arn   = "arn:aws:s3:::forms-staging-reliability-file-storage"
    reliability_file_storage_id    = "forms-reliability-file-storage"
  }
}
inputs = {
  reliability_storage_arn   = dependency.s3.outputs.reliability_file_storage_arn
  reliability_storage_id    = dependency.s3.outputs.reliability_file_storage_id
  }

include "root" {
  path = find_in_parent_folders("root.hcl")
}
