terraform {
  source = "../../../aws//s3"
}
dependencies {
  paths = ["../sqs"]
}

locals {
  aws_account_id = get_env("AWS_ACCOUNT_ID", "000000000000")
}


dependency "sqs" {
  config_path = "../sqs"

  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs = {
    sqs_file_upload_queue_arn = "arn:aws:sqs:ca-central-1:730335263169:file_upload"
    sqs_file_upload_queue_id  = "https://sqs.ca-central-1.amazonaws.com/${local.aws_account_id}/file_upload"

  }
}

inputs = {
  sqs_file_upload_arn = dependency.sqs.outputs.sqs_file_upload_queue_arn
  sqs_file_upload_id  = dependency.sqs.outputs.sqs_file_upload_queue_id
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}
