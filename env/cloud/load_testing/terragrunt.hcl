terraform {
  source = "../../../aws//load_testing"
}

dependencies {
  paths = ["../lambdas"]
}

dependency "lambdas" {
  config_path = "../lambdas"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    lambda_submission_function_name = "Submission"
  }
}

inputs = {
  lambda_submission_function_name = dependency.lambdas.outputs.lambda_submission_function_name
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}
