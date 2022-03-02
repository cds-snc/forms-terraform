terraform {
  source = "git::https://github.com/cds-snc/forms-terraform//aws/rds?ref=${get_env("TARGET_VERSION")}"
}

dependencies {
  paths = ["../network"]
}

dependency "network" {
  config_path = "../network"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    private_subnet_ids    = [""]
    rds_security_group_id = ""
  }
}

inputs = {
  private_subnet_ids    = dependency.network.outputs.private_subnet_ids
  rds_security_group_id = dependency.network.outputs.rds_security_group_id

  rds_db_name              = "forms"
  rds_db_subnet_group_name = "forms-db"
  rds_db_user              = "postgres"
  rds_name                 = "forms-db"
}

include {
  path = find_in_parent_folders()
}
