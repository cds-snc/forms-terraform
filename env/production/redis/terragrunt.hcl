terraform {
  source = "git::https://github.com/cds-snc/forms-terraform//aws/redis?ref=${get_env("TARGET_VERSION")}"
}

dependencies {
  paths = ["../network"]
}

dependency "network" {
  config_path = "../network"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    private_subnet_ids      = [""]
    redis_security_group_id = ""
  }
}

inputs = {
  private_subnet_ids      = dependency.network.outputs.private_subnet_ids
  redis_security_group_id = dependency.network.outputs.redis_security_group_id
}

include {
  path = find_in_parent_folders()
}
