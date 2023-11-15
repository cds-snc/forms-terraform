locals {
  account_id = get_env("AWS_ACCOUNT_ID", "")
  env = get_env("APP_ENV", "local")
  domains = get_env("APP_DOMAINS", "[\"localhost:3000\"]")
}

inputs = {
  account_id                = "${local.account_id}"
  billing_tag_key           = "CostCentre"
  billing_tag_value         = "forms-platform-${local.env}"   
  domains                    = local.domains
  env                       = "${local.env}"
  region                    = "ca-central-1"
  cbs_satellite_bucket_name = "cbs-satellite-${local.account_id}"
}


generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = local.env == "local" ? file("./common/local-provider.tf") : file("./common/provider.tf")
}

generate "common_variables" {
  path      = "common_variables.tf"
  if_exists = "overwrite"
  contents  = file("./common/common_variables.tf")
}
