terraform {
  source = "../../../aws//load_balancer"
}

dependencies {
  paths = ["../hosted_zone", "../network", "../maintenance_mode"]
}

dependency "hosted_zone" {
  config_path = "../hosted_zone"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    hosted_zone_ids = formatlist("mocked_zone_id_%s", local.domain)
  }
}

dependency "network" {
  config_path = "../network"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    alb_security_group_id = ""
    public_subnet_ids     = [""]
    vpc_id                = ""
  }
}

dependency "maintenance_mode" {
  config_path = "../maintenance_mode"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    gc_forms_application_health_check_id                    = ""
    maintenance_mode_cloudfront_distribution_domain_name    = ""
    maintenance_mode_cloudfront_distribution_hosted_zone_id = ""
  }
}

inputs = {
  hosted_zone_ids                                         = dependency.hosted_zone.outputs.hosted_zone_ids
  alb_security_group_id                                   = dependency.network.outputs.alb_security_group_id
  public_subnet_ids                                       = dependency.network.outputs.public_subnet_ids
  vpc_id                                                  = dependency.network.outputs.vpc_id
  gc_forms_application_health_check_id                    = dependency.maintenance_mode.outputs.gc_forms_application_health_check_id
  maintenance_mode_cloudfront_distribution_domain_name    = dependency.maintenance_mode.outputs.maintenance_mode_cloudfront_distribution_domain_name
  maintenance_mode_cloudfront_distribution_hosted_zone_id = dependency.maintenance_mode.outputs.maintenance_mode_cloudfront_distribution_hosted_zone_id
}

include {
  path = find_in_parent_folders()
}
