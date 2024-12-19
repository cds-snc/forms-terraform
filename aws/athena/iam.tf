data "aws_iam_policy_document" "athena_iam" {
  # Allow only prepared statements execution and related actions
  statement {
    sid = "AllowAthenaPreparedStatements"
    effect = "Allow"

    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "athena:QueryType"
      values   = ["PREPARED_STATEMENT"]
    }
  }

  # Explicitly deny any other query types to strengthen security
  statement {
    sid = "DenyNonPreparedStatements"
    effect = "Deny"

    actions = [
      "athena:StartQueryExecution"
    ]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "athena:QueryType"
      values   = ["PREPARED_STATEMENT"]
    }
  }
}
