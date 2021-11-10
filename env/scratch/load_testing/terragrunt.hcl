terraform {
  source = "../../../aws//load_testing"
}

include {
  path = find_in_parent_folders()
}
