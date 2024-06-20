locals {
  lambda_submission_expect_invocation_in_period = var.env == "production" ? var.lambda_submission_expect_invocation_in_period : 60 * 24 # expect once a day in non-prod envs
}
