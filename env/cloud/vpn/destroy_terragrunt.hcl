include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../local_dev_files//tf"
}
