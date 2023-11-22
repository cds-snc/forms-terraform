terraform {
  source = "../../../aws//s3"
}

include {
  path = find_in_parent_folders()
}

locals {
  env = get_env("APP_ENV", "local")
}


generate "import_existing_s3_buckets" {
  disable     = local.env == "local"
  path      = "import.tf"
  if_exists = "overwrite"
  contents  = <<EOF
import {
  to = aws_s3_bucket.reliability_file_storage
  id = "forms-${local.env}-reliability-file-storage"
}

import {
  to = aws_s3_bucket.archive_storage
  id = "forms-${local.env}-archive-storage"
}

import {
  to = aws_s3_bucket.vault_file_storage
  id = "forms-${local.env}-vault-file-storage"
}
EOF
}