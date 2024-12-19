terraform {
  source = "../../../aws//athena"
}

dependencies {
  paths = ["../buckets", "../glue"]
}

dependency "buckets" {
  config_path                             = "../buckets"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    athena_bucket_name = "mock-athena-bucket"
  }
}

dependency "glue" {
  config_path                             = "../glue"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    glue_database_name = "mock-glue-database"
  }
}

inputs = {
  athena_bucket_name = dependency.buckets.outputs.athena_bucket_name
  glue_database_name = dependency.glue.outputs.glue_database_name
}

include {
  path = find_in_parent_folders()
}