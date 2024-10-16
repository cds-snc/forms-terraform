terraform {
  source = "../../../aws//load_testing"
}

dependencies {
  paths = ["../ecr", "../lambdas"]
}

dependency "ecr" {
  config_path = "../ecr"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    ecr_repository_url_load_testing_lambda = ""
  }
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
  ecr_repository_url_load_testing_lambda = dependency.ecr.outputs.ecr_repository_url_load_testing_lambda
  lambda_submission_function_name        = dependency.lambdas.outputs.lambda_submission_function_name
}

include {
  path = find_in_parent_folders()
}
