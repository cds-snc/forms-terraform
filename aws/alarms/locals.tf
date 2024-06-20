locals {
  lambda_submission_expect_invocation_in_period = var.env == "production" ? var.lambda_submission_expect_invocation_in_period : 60 * 24 * 7 # expect once a week in non-prod envs
}
