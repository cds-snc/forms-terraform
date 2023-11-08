terraform {
  source = "../../../aws//maintenance_mode"
}

include {
  path = find_in_parent_folders()
}
