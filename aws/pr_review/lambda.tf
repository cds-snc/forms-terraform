resource "aws_lambda_permission" "submission_lambda_invoke" {
  count         = var.env == "staging" ? 1 : 0
  statement_id  = "AllowSubmissionInvokeFromPRReviewEnvs"
  action        = "lambda:InvokeFunction"
  principal     = aws_iam_role.forms_lambda_client.arn
  function_name = var.forms_submission_lambda_name
}
