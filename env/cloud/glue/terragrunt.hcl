terraform {
  source = "../../../aws//glue"
}

dependencies {
  paths = ["../network", "../s3", "../rds"]
}

locals {
  aws_account_id = get_env("AWS_ACCOUNT_ID", "000000000000")
}

dependency "network" {
  config_path                             = "../network"
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    glue_job_security_group_id = "mock-sg-12345678"
  }
}

dependency "s3" {
  config_path                             = "../s3"
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
    rds_cluster_reader_endpoint            = "mock-rds-cluster-endpoint"
    rds_cluster_instance_availability_zone = "mock-ca-central-1"
    rds_cluster_instance_identifier        = "mock-forms-database-identifier"
    rds_cluster_instance_subnet_id         = "mock-sg-12345678"
    rds_connector_secret_arn               = "arn:aws:secretsmanager:ca-central-1:${local.aws_account_id}:secret:mock-rds-connector"
    rds_connector_secret_name              = "mock-rds-connector"
  }
}

inputs = {
  datalake_bucket_arn                    = dependency.s3.outputs.lake_bucket_arn
  datalake_bucket_name                   = dependency.s3.outputs.lake_bucket_name
  etl_bucket_arn                         = dependency.s3.outputs.etl_bucket_arn
  etl_bucket_name                        = dependency.s3.outputs.etl_bucket_name
  glue_job_security_group_id             = dependency.network.outputs.glue_job_security_group_id
  rds_db_name                            = dependency.rds.outputs.rds_db_name
  rds_cluster_reader_endpoint            = dependency.rds.outputs.rds_cluster_reader_endpoint
  rds_port                               = "5432"
  rds_cluster_instance_availability_zone = dependency.rds.outputs.rds_cluster_instance_availability_zone
  rds_cluster_instance_identifier        = dependency.rds.outputs.rds_cluster_instance_identifier
  rds_cluster_instance_subnet_id         = dependency.rds.outputs.rds_cluster_instance_subnet_id
  rds_connector_secret_arn               = dependency.rds.outputs.rds_connector_secret_arn
  rds_connector_secret_name              = dependency.rds.outputs.rds_connector_secret_name
  s3_endpoint                            = "s3://"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}