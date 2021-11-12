terraform {
  source = "../../../aws//ecr"
}

include {
  path = find_in_parent_folders()
}
