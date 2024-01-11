terraform {
  source = "../../../aws//oidc_roles"
}

include {
  path = find_in_parent_folders()
}