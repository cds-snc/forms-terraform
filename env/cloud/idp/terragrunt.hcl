terraform {
  source = "../../../aws//idp"
}

dependencies {
  paths = ["../hosted_zone", "../network", "../ecr", "../load_balancer", "../kms", "../secrets"]
}

locals {
  aws_account_id = get_env("AWS_ACCOUNT_ID", "000000000000")
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
    idp_db_security_group_id                               = "sg-db"
    idp_ecs_security_group_id                              = "sg-ecs"
    idp_lb_security_group_id                               = "sg-lb"
    code_build_security_group_id                           = "sg-cb"
    private_subnet_ids                                     = ["prv-1", "prv-2"]
    public_subnet_ids                                      = ["pub-1", "pub-2"]
    vpc_id                                                 = "vpc-id"
    service_discovery_private_dns_namespace_ecs_local_id   = ""
    service_discovery_private_dns_namespace_ecs_local_name = "ecs.local"
  }
}

dependency "ecr" {
  config_path = "../ecr"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    ecr_repository_url_idp             = "https://${local.aws_account_id}.dkr.ecr.ca-central-1.amazonaws.com/idp/zitadel"
    ecr_repository_url_idp_user_portal = "https://${local.aws_account_id}.dkr.ecr.ca-central-1.amazonaws.com/idp/user_portal"
  }
}

dependency "load_balancer" {
  config_path = "../load_balancer"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    kinesis_firehose_waf_logs_arn = "arn:aws:firehose:ca-central-1:${local.aws_account_id}:deliverystream/waf-logs"
    waf_ipv4_blocklist_arn        = "arn:aws:wafv2:ca-central-1:${local.aws_account_id}:ipset/mock-ip-blocklist/abcd1234-efgh5678-ijkl9012"
  }
}


dependency "kms" {
  config_path                             = "../kms"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    kms_key_cloudwatch_arn = null
  }
}

dependency "secrets" {
  config_path                             = "../secrets"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    notify_api_key_secret_arn = "arn:aws:secretsmanager:ca-central-1:${local.aws_account_id}:secret:notify_api_key"
  }
}


inputs = {
  hosted_zone_ids = dependency.hosted_zone.outputs.hosted_zone_ids

  private_subnet_ids                                     = dependency.network.outputs.private_subnet_ids
  public_subnet_ids                                      = dependency.network.outputs.public_subnet_ids
  security_group_idp_db_id                               = dependency.network.outputs.idp_db_security_group_id
  security_group_idp_ecs_id                              = dependency.network.outputs.idp_ecs_security_group_id
  security_group_idp_lb_id                               = dependency.network.outputs.idp_lb_security_group_id
  code_build_security_group_id                           = dependency.network.outputs.code_build_security_group_id
  vpc_id                                                 = dependency.network.outputs.vpc_id
  service_discovery_private_dns_namespace_ecs_local_id   = dependency.network.outputs.service_discovery_private_dns_namespace_ecs_local_id
  service_discovery_private_dns_namespace_ecs_local_name = dependency.network.outputs.service_discovery_private_dns_namespace_ecs_local_name

  zitadel_image_ecr_url = dependency.ecr.outputs.ecr_repository_url_idp
  zitadel_image_tag     = "latest" # TODO: pin to specific tag for prod

  idp_login_ecr_url = dependency.ecr.outputs.ecr_repository_url_idp_user_portal

  kinesis_firehose_waf_logs_arn = dependency.load_balancer.outputs.kinesis_firehose_waf_logs_arn
  waf_ipv4_blocklist_arn        = dependency.load_balancer.outputs.waf_ipv4_blocklist_arn

  kms_key_cloudwatch_arn = dependency.kms.outputs.kms_key_cloudwatch_arn

  notify_api_key_secret_arn = dependency.secrets.outputs.notify_api_key_secret_arn

  # 1 ACU ~= 2GB of memory and 1vCPU
  idp_database_min_acu = 1
  idp_database_max_acu = 4

  # Overwritten in GitHub Actions by TFVARS
  idp_login_service_user_token    = "ServiceUserTokenValue"
  gc_template_id                  = "0123456789"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}
