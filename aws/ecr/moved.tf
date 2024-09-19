moved {
  from = aws_ecr_repository.idp[0]
  to   = aws_ecr_repository.idp
}

moved {
  from = aws_ecr_lifecycle_policy.idp[0]
  to   = aws_ecr_lifecycle_policy.idp
}

moved {
  from = aws_ecr_repository.api[0]
  to   = aws_ecr_repository.api
}

moved {
  from = aws_ecr_lifecycle_policy.api[0]
  to   = aws_ecr_lifecycle_policy.api
}
