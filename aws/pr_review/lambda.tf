resource "aws_lambda_permission" "submission_lambda_invoke" {
  count          = var.env == "staging" ? 1 : 0
  statement_id   = "AllowSubmissionInvokeFromPRReviewEnvs"
  action         = "lambda:InvokeFunction"
  principal      = "lambda.amazonaws.com"
  function_name  = var.forms_submission_lambda_name
  source_account = var.account_id
}
