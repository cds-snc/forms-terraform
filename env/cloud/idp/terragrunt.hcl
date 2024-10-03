terraform {
  source = "../../../aws//idp"
}

dependencies {
  paths = ["../hosted_zone", "../network", "../ecr", "../load_balancer"]
}

dependency "hosted_zone" {
  config_path = "../hosted_zone"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    hosted_zone_ids = ["Z123456789012"]
  }
}

dependency "network" {
  config_path                             = "../network"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    idp_db_security_group_id  = "sg-db"
    idp_ecs_security_group_id = "sg-ecs"
    idp_lb_security_group_id  = "sg-lb"
    private_subnet_ids        = ["prv-1", "prv-2"]
    public_subnet_ids         = ["pub-1", "pub-2"]
    vpc_id                    = "vpc-id"
  }
}

dependency "ecr" {
  config_path = "../ecr"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    ecr_repository_url_idp = "https://123456789012.dkr.ecr.ca-central-1.amazonaws.com/idp/zitadel"
  }
}

dependency "load_balancer" {
  config_path = "../load_balancer"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    kinesis_firehose_waf_logs_arn = "arn:aws:firehose:ca-central-1:123456789012:deliverystream/waf-logs"
    waf_ipv4_blocklist_arn        = "arn:aws:wafv2:ca-central-1:123456789012:ipset/mock-ip-blocklist/abcd1234-efgh5678-ijkl9012"
  }
}

inputs = {
  hosted_zone_ids = dependency.hosted_zone.outputs.hosted_zone_ids

  private_subnet_ids        = dependency.network.outputs.private_subnet_ids
  public_subnet_ids         = dependency.network.outputs.public_subnet_ids
  security_group_idp_db_id  = dependency.network.outputs.idp_db_security_group_id
  security_group_idp_ecs_id = dependency.network.outputs.idp_ecs_security_group_id
  security_group_idp_lb_id  = dependency.network.outputs.idp_lb_security_group_id
  vpc_id                    = dependency.network.outputs.vpc_id

  zitadel_image_ecr_url = dependency.ecr.outputs.ecr_repository_url_idp
  zitadel_image_tag     = "latest" # TODO: pin to specific tag for prod

  kinesis_firehose_waf_logs_arn = dependency.load_balancer.outputs.kinesis_firehose_waf_logs_arn
  waf_ipv4_blocklist_arn        = dependency.load_balancer.outputs.waf_ipv4_blocklist_arn

  # 1 ACU ~= 2GB of memory and 1vCPU
  idp_database_min_acu = 3
  idp_database_max_acu = 4
}

include {
  path = find_in_parent_folders()
}
