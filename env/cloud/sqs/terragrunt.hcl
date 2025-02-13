terraform {
  source = "../../../aws//sqs"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}
