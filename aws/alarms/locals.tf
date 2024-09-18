locals {
  # Define the pattern that will be used to detect errors in the IdP logs
  # Any log message that contains a word from `idp_error` and does not contain a word from `idp_error_ignore` will be detected
  idp_error         = ["level=error"]
  idp_error_ignore  = ["context canceled"]
  idp_error_pattern = "[(w1=\"*${join("*\" || w1=\"*", local.idp_error)}*\") && w1!=\"*${join("*\" && w1!=\"*", local.idp_error_ignore)}*\"]"

  lambda_submission_expect_invocation_in_period = var.env == "production" ? var.lambda_submission_expect_invocation_in_period : 60 * 24 # expect once a day in non-prod envs
}
