terraform {
  source = "../../../aws//api"
}

dependencies {
  paths = ["../kms", "../network", "../dynamodb", "../load_balancer", "../ecr", "../s3", "../app"]
}

dependency "app" {
  config_path = "../app"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    ecs_cluster_name = "Forms"
  }
}

dependency "dynamodb" {
  config_path = "../dynamodb"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    dynamodb_vault_arn = "arn:aws:dynamodb:ca-central-1:123456789012:table/Vault"
  }
}

dependency "ecr" {
  config_path = "../ecr"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    ecr_repository_url_api = "123456789012.dkr.ecr.ca-central-1.amazonaws.com/forms/api"
  }
}

dependency "kms" {
  config_path                             = "../kms"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    kms_key_dynamodb_arn = "arn:aws:kms:ca-central-1:123456789012:key/12345678-796a-461b-9f69-b0e0c40f5d0a"
  }
}

dependency "load_balancer" {
  config_path                             = "../load_balancer"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    lb_target_group_api_arn = "arn:aws:elasticloadbalancing:ca-central-1:123456789012:targetgroup/forms-api/1234567890abcdef"
  }
}

dependency "network" {
  config_path                             = "../network"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    api_ecs_security_group_id = "sg-1234567890"
    private_subnet_ids        = ["prv-1", "prv-2"]
  }
}

dependency "s3" {
  config_path                             = "../s3"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    vault_file_storage_arn = "arn:aws:s3:::forms-mock-vault-file-storage"
  }
}

locals {
  zitadel_domain            = get_env("ZITADEL_PROVIDER", "https://localhost")
}

inputs = {
  api_image_tag = "latest"

  api_image_ecr_url           = dependency.ecr.outputs.ecr_repository_url_api
  dynamodb_vault_arn          = dependency.dynamodb.outputs.dynamodb_vault_arn
  ecs_cluster_name            = dependency.app.outputs.ecs_cluster_name
  kms_key_dynamodb_arn        = dependency.kms.outputs.kms_key_dynamodb_arn
  lb_target_group_arn_api_ecs = dependency.load_balancer.outputs.lb_target_group_api_arn
  private_subnet_ids          = dependency.network.outputs.private_subnet_ids
  security_group_id_api_ecs   = dependency.network.outputs.api_ecs_security_group_id
  s3_vault_file_storage_arn   = dependency.s3.outputs.vault_file_storage_arn
  zitadel_administration_key_secret_arn   = dependency.secrets.outputs.zitadel_application_key_secret_arn

  zitadel_domain              = local.zitadel_provider

}

include {
  path = find_in_parent_folders()
}
