terraform {
  source = "../../../aws//load_testing"
}

dependencies {
  paths = ["../ecr"]
}

dependency "ecr" {
  config_path = "../ecr"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state = "no_merge"
  mock_outputs = {
    ecr_repository_url_load_test = ""
  }
}

inputs = {
  ecr_repository_url_load_test = dependency.ecr.outputs.ecr_repository_url_load_test
}

include {
  path = find_in_parent_folders()
}
