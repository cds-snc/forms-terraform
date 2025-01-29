terraform {
  source = "../../../aws//s3"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = get_env("APP_ENV", "local")
}
