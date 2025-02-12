terraform {
  source = "../../../aws//rds"
}

dependencies {
  paths = ["../network"]
}

dependency "network" {
  config_path                             = "../network"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    private_subnet_ids    = [""]
    rds_security_group_id = null
  }
}

locals {
  env = get_env("APP_ENV", "local")
}

inputs = {
  private_subnet_ids    = dependency.network.outputs.private_subnet_ids
  rds_security_group_id = dependency.network.outputs.rds_security_group_id

  rds_connector_db_user    = local.env == "development" ? "postgres" : "rds_connector_read"
  rds_db_user              = "postgres"
  rds_db_name              = "forms"
  rds_name                 = local.env == "staging" ? "forms-staging-db" : "forms-db"
  rds_db_subnet_group_name = local.env == "staging" ? "forms-staging-db" : "forms-db"

  # Overwritten in GitHub Actions by TFVARS
  rds_db_password           = "chummy000" # RDS database password used for local setup
  rds_connector_db_password = "chummy000"

}

include "root" {
  path = find_in_parent_folders("root.hcl")
}
