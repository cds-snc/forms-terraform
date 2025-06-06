terraform {
  source = "../../../aws//file_scanning"
}



include "root" {
  path = find_in_parent_folders("root.hcl")
}