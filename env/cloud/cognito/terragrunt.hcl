terraform {
  source = "../../../aws//cognito"
}

dependencies {
  paths = ["../kms", "../secrets", "../ecr"]
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
    notify_api_key_secret_arn = "arn:aws:secretsmanager:ca-central-1:123456789012:secret:notify_api_key"
  }
}

dependency "ecr" {
  config_path                             = "../ecr"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    ecr_repository_url_cognito_email_sender_lambda = ""
    ecr_repository_url_cognito_pre_sign_up_lambda  = ""
  }
}

inputs = {
  kms_key_cloudwatch_arn = dependency.kms.outputs.kms_key_cloudwatch_arn

  notify_api_key_secret_arn = dependency.secrets.outputs.notify_api_key_secret_arn

  ecr_repository_url_cognito_email_sender_lambda = dependency.ecr.outputs.ecr_repository_url_cognito_email_sender_lambda
  ecr_repository_url_cognito_pre_sign_up_lambda  = dependency.ecr.outputs.ecr_repository_url_cognito_pre_sign_up_lambda
}

include {
  path = find_in_parent_folders()
}