terraform {
  source = "../../../aws//pr_review"
}

dependencies {
  paths = ["../app", "../network"]
}

dependency "app" {
  config_path = "../app"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_with_state           = true
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    lambda_submission_function_name          = "Submission"
    ecs_iam_forms_secrets_manager_policy_arn = ""
    ecs_iam_forms_kms_policy_arn             = ""
    ecs_iam_forms_s3_policy_arn              = ""
    ecs_iam_forms_dynamodb_policy_arn        = ""
    ecs_iam_forms_sqs_policy_arn             = ""
    ecs_iam_forms_cognito_policy_arn         = ""
  }
}

dependency "network" {
  config_path = "../network"

  mock_outputs_allowed_terraform_commands = ["init", "fmt", "validate", "plan", "show"]
  mock_outputs_merge_with_state           = true
  mock_outputs_merge_strategy_with_state  = "shallow"
  mock_outputs = {
    vpc_id                           = ""
    privatelink_security_group_id    = ""
    forms_database_security_group_id = ""
    forms_redis_security_group_id    = ""
  }
}

inputs = {
  vpc_id                                   = dependency.network.outputs.vpc_id
  ecs_iam_forms_secrets_manager_policy_arn = dependency.app.outputs.ecs_iam_forms_secrets_manager_policy_arn
  ecs_iam_forms_kms_policy_arn             = dependency.app.outputs.ecs_iam_forms_kms_policy_arn
  ecs_iam_forms_s3_policy_arn              = dependency.app.outputs.ecs_iam_forms_s3_policy_arn
  ecs_iam_forms_dynamodb_policy_arn        = dependency.app.outputs.ecs_iam_forms_dynamodb_policy_arn
  ecs_iam_forms_sqs_policy_arn             = dependency.app.outputs.ecs_iam_forms_sqs_policy_arn
  ecs_iam_forms_cognito_policy_arn         = dependency.app.outputs.ecs_iam_forms_cognito_policy_arn
  privatelink_security_group_id            = dependency.network.outputs.privatelink_security_group_id
  forms_database_security_group_id         = dependency.network.outputs.rds_security_group_id
  forms_redis_security_group_id            = dependency.network.outputs.redis_security_group_id
  forms_submission_lambda_name             = dependency.app.outputs.lambda_submission_function_name
}

include {
  path = find_in_parent_folders()
}