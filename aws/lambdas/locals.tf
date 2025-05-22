locals {
  vpc_config = var.env == "development" ? [] : [{
    security_group_ids = [var.lambda_security_group_id]
    subnet_ids         = var.private_subnet_ids
  }]
  # Use account ID instead of environment name when in local development
  env = var.env == "development" ? var.account_id : var.env
}

