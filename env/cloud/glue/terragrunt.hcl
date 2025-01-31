terraform {
  source = "../../../aws//glue"
}

dependencies {
  paths = ["../network", "../buckets", "../rds"]
}

dependency "network" {
  config_path                             = "../network"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    glue_job_security_group_id = "mock-sg-12345678"
  }
}

dependency "buckets" {
  config_path                             = "../buckets"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    lake_bucket_arn  = "arn:aws:s3:::mock-datalake-bucket"
    lake_bucket_name = "mock-datalake-bucket"
    etl_bucket_arn   = "arn:aws:s3:::mock-etl-bucket"
    etl_bucket_name  = "mock-etl-bucket"
  }
}

dependency "rds" {
  config_path                             = "../rds"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    rds_db_name                            = "mock-rds-db-name"
    rds_cluster_endpoint                   = "mock-rds-cluster-endpoint"
    rds_cluster_instance_availability_zone = "mock-ca-central-1"
    rds_cluster_instance_identifier        = "mock-forms-database-identifier"
    rds_cluster_instance_subnet_id         = "mock-sg-12345678"
    rds_connector_secret_arn               = "arn:aws:secretsmanager:ca-central-1:123456789012:secret:mock-rds-connector"
    rds_connector_secret_name              = "mock-rds-connector"
  }
}

locals {
  env = get_env("APP_ENV", "local")
}

inputs = {
  datalake_bucket_arn                    = dependency.buckets.outputs.lake_bucket_arn
  datalake_bucket_name                   = dependency.buckets.outputs.lake_bucket_name
  etl_bucket_arn                         = dependency.buckets.outputs.etl_bucket_arn
  etl_bucket_name                        = dependency.buckets.outputs.etl_bucket_name
  glue_job_security_group_id             = dependency.network.outputs.glue_job_security_group_id
  rds_db_name                            = dependency.rds.outputs.rds_db_name
  rds_cluster_endpoint                   = dependency.rds.outputs.rds_cluster_endpoint
  rds_port                               = local.env == "local" ? "4510" : "5432" # Localstack is accessed on 4510, AWS on 5432
  rds_cluster_instance_availability_zone = dependency.rds.outputs.rds_cluster_instance_availability_zone
  rds_cluster_instance_identifier        = dependency.rds.outputs.rds_cluster_instance_identifier
  rds_cluster_instance_subnet_id         = dependency.rds.outputs.rds_cluster_instance_subnet_id
  rds_connector_secret_arn               = dependency.rds.outputs.rds_connector_secret_arn
  rds_connector_secret_name              = dependency.rds.outputs.rds_connector_secret_name
  s3_endpoint                            = local.env == "local" ? "http://127.0.0.1:4566/" : "s3://"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}