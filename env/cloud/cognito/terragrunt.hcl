terraform {
  source = "../../../aws//cognito"
}

include {
  path = find_in_parent_folders()
}
