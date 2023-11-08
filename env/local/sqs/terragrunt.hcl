terraform {
  source = "../../../aws//sqs"
}

include {
  path = find_in_parent_folders()
}

