terraform {
  source = "../../../aws//ecr"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  cds_org_id         = get_env("CDS_ORG_ID", "o-1234567890")
  staging_account_id = get_env("STAGING_AWS_ACCOUNT_ID", "123456789012")

}

inputs = {
  cds_org_id         = local.cds_org_id
  staging_account_id = local.staging_account_id
  aws_development_accounts = ["123456789012"]
}

