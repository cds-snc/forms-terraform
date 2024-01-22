terraform {
  source = "../../../aws//s3"
}

include {
  path = find_in_parent_folders()
}

locals {
  env = get_env("APP_ENV", "local")
}
