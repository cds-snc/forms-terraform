terraform {
  source = "../../../aws//athena"
}

dependencies {
  paths = ["../s3"]
}

dependency "s3" {
  config_path                             = "../s3"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    athena_bucket_name = "mock-athena-bucket"
  }
}

inputs = {
  athena_bucket_name = dependency.buckets.outputs.athena_bucket_name
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}