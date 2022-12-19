terraform {
  source = "../../../aws//kms"
}

dependencies {
  paths = ["../cognito"]
}

dependency "cognito" {
  config_path = "../cognito"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_with_state           = true
  mock_outputs = {
    cognito_endpoint_url  = ""
    cognito_client_id     = ""
    cognito_user_pool_arn = ""
    cognito_user_pool_id  = ""
  }
}

inputs = {
  cognito_user_pool_id = dependency.cognito.outputs.cognito_user_pool_id
}

include {
  path = find_in_parent_folders()
}
