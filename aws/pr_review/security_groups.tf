#
# Security group allowing the lambda forms-client PR review environment to communicate
# with Redis, DB, and receive recieve HTTPS requests.
#
resource "aws_security_group" "lambda_client_pr_review" {
  count = var.env == "staging" ? 1 : 0

  name        = "lambda-admin-pr-review"
  description = "Lambda admin PR review environment"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "internet_ingress_to_lambda_client" {
  count = var.env == "staging" ? 1 : 0

  description       = "Allow inbound connections from the internet to the lambda PR review env"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda_client_pr_review[0].id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "lambda_client_egress_to_internet" {
  count = var.env == "staging" ? 1 : 0

  description       = "Allow outbound connections from lambda PR review env to the internet"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda_client_pr_review[0].id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "lambda_client_egress_privatelink" {
  count = var.env == "staging" ? 1 : 0

  description              = "Security group rule for Forms egress through privatelink"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda_client_pr_review[0].id
  source_security_group_id = var.privatelink_security_group_id
}

resource "aws_security_group_rule" "privatelink_lambda_client_ingress" {
  count = var.env == "staging" ? 1 : 0

  description              = "Security group rule for Forms ingress"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = var.privatelink_security_group_id
  source_security_group_id = aws_security_group.lambda_client_pr_review[0].id
}

resource "aws_security_group_rule" "lambda_client_egress_database" {
  count = var.env == "staging" ? 1 : 0

  description              = "Security group rule for Forms DB egress to Database"
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda_client_pr_review[0].id
  source_security_group_id = var.forms_database_security_group_id
}

resource "aws_security_group_rule" "database_lambda_client_ingress" {
  count = var.env == "staging" ? 1 : 0

  description              = "Security group rule for Forms DB ingress"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.forms_database_security_group_id
  source_security_group_id = aws_security_group.lambda_client_pr_review[0].id
}

resource "aws_security_group_rule" "lambda_client_egress_redis" {
  count = var.env == "staging" ? 1 : 0

  description              = "Security group rule for Forms DB egress to Redis"
  type                     = "egress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda_client_pr_review[0].id
  source_security_group_id = var.forms_redis_security_group_id
}

resource "aws_security_group_rule" "redis_lambda_client_ingress" {
  count = var.env == "staging" ? 1 : 0

  description              = "Security group rule for Forms Redis ingress"
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = var.forms_redis_security_group_id
  source_security_group_id = aws_security_group.lambda_client_pr_review[0].id
}
