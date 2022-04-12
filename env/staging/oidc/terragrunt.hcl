terraform {
  source = "../../../aws//oidc"
}

include {
  path = find_in_parent_folders()
}
