terraform {
  source = "../../../aws//kms"
}

include {
  path = find_in_parent_folders()
}
