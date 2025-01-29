terraform {
  source = "../../../aws//oidc_roles"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}