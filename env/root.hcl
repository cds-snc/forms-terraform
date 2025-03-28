locals {
  account_id       = get_env("AWS_ACCOUNT_ID", "000000000000")
  env              = get_env("APP_ENV", "development")
  domain_api       = get_env("API_DOMAIN", "localhost:3001") 
  domain_idp       = get_env("IDP_DOMAIN", "localhost:8080")
  domains          = get_env("APP_DOMAINS", "[\"localhost:3000\"]")
}

inputs = {
  account_id                = "${local.account_id}"
  billing_tag_key           = "CostCentre"
  billing_tag_value         = "forms-platform-${local.env}"
  domain_api                = local.domain_api  
  domain_idp                = local.domain_idp   
  domains                   = local.domains
  env                       = "${local.env}"
  region                    = "ca-central-1"
  cbs_satellite_bucket_name = "cbs-satellite-${local.account_id}"
}

generate "backend_remote_state" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "s3" {
    encrypt        = true
    use_path_style = true
    bucket         = "forms-${local.env == "development" ? local.account_id : local.env}-tfstate"
    dynamodb_table = "tfstate-lock"
    region         = "ca-central-1"
    key            = "${path_relative_to_include("root")}/terraform.tfstate"
  }
}
EOF
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = file("./common/provider.tf")
}

generate "common_variables" {
  path      = "common_variables.tf"
  if_exists = "overwrite"
  contents  = file("./common/common_variables.tf")
}
