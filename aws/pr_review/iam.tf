# data "aws_iam_policy_document" "forms_lambda_parameter_store" {
#   count = var.env == "staging" ? 1 : 0

#   statement {
#     actions = ["ssm:GetParameters"]
#     effect  = "Allow"
#     resources = [
#       "arn:aws:ssm:ca-central-1:${var.account_id}:parameter/form-viewer/env"
#     ]
#   }
# }

# resource "aws_iam_policy" "forms_lambda_parameter_store" {
#   count = var.env == "staging" ? 1 : 0

#   name   = "formsLambdaParameterStoreRetrieval"
#   path   = "/"
#   policy = data.aws_iam_policy_document.forms_lambda_parameter_store[0].json
# }

# resource "aws_iam_role_policy_attachment" "forms_lambda_parameter_store" {
#   count = var.env == "staging" ? 1 : 0

#   role       = aws_iam_role.forms_lambda_client[0].name
#   policy_arn = aws_iam_policy.forms_lambda_parameter_store[0].arn
# }
