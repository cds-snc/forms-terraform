resource "aws_lambda_permission" "submission_lambda_invoke" {
  statement_id  = "AllowSubmissionInvokeFromPRReviewEnvs"
  action        = "lambda:InvokeFunction"
  principal     = aws_iam_role.forms_lambda_client.arn
  function_name = var.forms_submission_lambda_name
}
