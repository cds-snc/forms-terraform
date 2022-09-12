terraform {
  source = "../../../aws//dynamodb"
}

include {
  path = find_in_parent_folders()
}
