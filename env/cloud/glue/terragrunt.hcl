terraform {
  source = "../../../aws//glue"
}

dependencies {
  paths = ["../buckets", "../rds"]
}

dependency "buckets" {
  config_path                             = "../buckets"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    datalake_bucket_arn          = "arn:aws:s3:::mock-datalake-bucket"
    datalake_bucket_name         = "mock-datalake-bucket"
    etl_bucket_arn               = "arn:aws:s3:::mock-etl-bucket"
    etl_bucket_name              = "mock-etl-bucket"
  }
}

dependency "rds" {
  config_path                             = "../rds"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    rds_db_name                  = "mock-rds-db-name"
    rds_db_user                  = "mock-rds-db-user"
    rds_db_password              = "mock-rds-db-password"
    rds_cluster_endpoint         = "mock-rds-cluster-endpoint"
  }
}

locals {
  env = get_env("APP_ENV", "local")
}

inputs = {
  datalake_bucket_arn          = dependency.buckets.outputs.lake_bucket_arn
  datalake_bucket_name         = dependency.buckets.outputs.lake_bucket_name
  etl_bucket_arn               = dependency.buckets.outputs.etl_bucket_arn
  etl_bucket_name              = dependency.buckets.outputs.etl_bucket_name
  rds_db_name                  = "forms"
  rds_db_user                  = local.env == "local" ? "localstack_postgres" : "postgres" # We cannot use `postgres` as a username in Localstack
  rds_db_password              = "chummy" # RDS database password used for local setup TODO: < this.
  rds_cluster_endpoint         = dependency.rds.outputs.rds_cluster_endpoint
}

include {
  path = find_in_parent_folders()
}