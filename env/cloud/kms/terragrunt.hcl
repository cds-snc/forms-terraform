terraform {
  source = "../../../aws//kms"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}
