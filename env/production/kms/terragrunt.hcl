terraform {
  source = "git::https://github.com/cds-snc/forms-terraform//aws/kms?ref=${get_env("TARGET_VERSION")}"
}

include {
  path = find_in_parent_folders()
}
