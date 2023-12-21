terraform {
  source = "../../../aws//cognito"
}

dependencies {
  source = ["../kms", "../secrets"]
}


dependency "kms" {
  config_path = "../kms"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    kms_key_cloudwatch_arn = null
  }
}

dependency "secrets" {
  config_path                             = "../secrets"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    notify_api_key_secret_arn               = null
  }
}


inputs = {
  kms_key_cloudwatch_arn = dependency.kms.outputs.kms_key_cloudwatch_arn
  notify_api_key_secret_arn = dependency.secrets.outputs.notify_api_key_secret_arn
}

include {
  path = find_in_parent_folders()
}