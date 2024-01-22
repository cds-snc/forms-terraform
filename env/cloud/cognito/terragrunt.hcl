terraform {
  source = "../../../aws//cognito"
}

dependencies {
  paths = ["../kms", "../secrets", "../s3"]
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

dependency "s3" {
  config_path                             = "../s3"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    lambda_code_arn = "arn:aws:s3:::forms-staging-lambda-code"
    lambda_code_id  = "forms-staging-lambda-code"
  }
}


inputs = {
  kms_key_cloudwatch_arn = dependency.kms.outputs.kms_key_cloudwatch_arn
  notify_api_key_secret_arn = dependency.secrets.outputs.notify_api_key_secret_arn
  lambda_code_arn              = dependency.s3.outputs.lambda_code_arn
  lambda_code_id               = dependency.s3.outputs.lambda_code_id
}

include {
  path = find_in_parent_folders()
}