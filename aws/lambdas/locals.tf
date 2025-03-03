locals {
  vpc_config = var.env == "development" ? [] : [{
    security_group_ids = [var.lambda_security_group_id]
    subnet_ids         = var.private_subnet_ids
  }]
}