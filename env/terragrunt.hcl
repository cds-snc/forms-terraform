locals {
  vars = read_terragrunt_config("../env_vars.hcl")
  local-generate = {
    if_exists = "overwrite_terragrunt"
    path = "../../terraform.tfstate"
  }
  local-config = {
    path = "../../terraform.tfstate"
  }

  s3-generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  s3-config = {
    encrypt        = true
    bucket         = "forms-${local.vars.inputs.env}-tfstate"
    dynamodb_table = "tfstate-lock"
    region         = local.vars.inputs.env == "local" ? "us-east-1": "ca-central-1"
    key            = "${path_relative_to_include()}/terraform.tfstate"
  }
}

inputs = {
  account_id        = local.vars.inputs.env == "local"? "" : "${local.vars.inputs.account_id}"
  billing_tag_key   = "CostCentre"
  billing_tag_value = "forms-platform-${local.vars.inputs.env}"   
  domain            = local.vars.inputs.env == "local"? "" :"${local.vars.inputs.domain}"
  env               = "${local.vars.inputs.env}"
  region            = local.vars.inputs.env == "local" ? "us-east-1":"ca-central-1"
}


remote_state {
  backend = local.vars.inputs.env == "local" ? "local" : "s3"
  generate = local.vars.inputs.env == "local" ? local.local-generate : local.s3-generate
  config = local.vars.inputs.env == "local" ? local.local-config : local.s3-generate
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = local.vars.inputs.env == "local" ? file("./common/local-provider.tf") : file("./common/provider.tf")
}

generate "common_variables" {
  path      = "common_variables.tf"
  if_exists = "overwrite"
  contents  = file("./common/common_variables.tf")
}
