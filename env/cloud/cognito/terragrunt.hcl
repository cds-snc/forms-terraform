terraform {
  source = "../../../aws//cognito"
}


dependency "kms" {
  config_path = "../kms"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    kms_key_cloudwatch_arn = ""
  }
}

inputs = {
  kms_key_cloudwatch_arn = dependency.kms.outputs.kms_key_cloudwatch_arn
}

include {
  path = find_in_parent_folders()
}