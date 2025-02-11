terraform {
  source = "../../../aws//ecr"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  cds_org_id = get_env("CDS_ORG_ID", "o-1234567890")
}

inputs = {
  cds_org_id = local.cds_org_id
}