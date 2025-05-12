resource "aws_security_group" "api_end_to_end_test_lambda" {
  description = "API end to end test Lambda"
  name        = "api_end_to_end_test_lambda"
  vpc_id      = aws_vpc.forms.id
}

resource "aws_security_group_rule" "local_lambda_to_idp" {
  description              = "Egress from Lambda to IdP for local communication"
  type                     = "egress"
  security_group_id        = aws_security_group.api_end_to_end_test_lambda.id
  source_security_group_id = aws_security_group.idp_ecs.id
  protocol                 = "tcp"
  from_port                = 8080
  to_port                  = 8080
}

resource "aws_security_group_rule" "local_lambda_to_api" {
  description              = "Ingress to IdP from Lambda for local communication"
  type                     = "ingress"
  security_group_id        = aws_security_group.idp_ecs.id
  source_security_group_id = aws_security_group.api_end_to_end_test_lambda.id
  protocol                 = "tcp"
  from_port                = 8080
  to_port                  = 8080
}

resource "aws_security_group_rule" "local_lambda_to_api" {
  description              = "Egress from Lambda to API for local communication"
  type                     = "egress"
  security_group_id        = aws_security_group.api_end_to_end_test_lambda.id
  source_security_group_id = aws_security_group.api_ecs.id
  protocol                 = "tcp"
  from_port                = 3001
  to_port                  = 3001
}

resource "aws_security_group_rule" "local_lambda_to_api" {
  description              = "Ingress to API from Lambda for local communication"
  type                     = "ingress"
  security_group_id        = aws_security_group.api_ecs.id
  source_security_group_id = aws_security_group.api_end_to_end_test_lambda.id
  protocol                 = "tcp"
  from_port                = 3001
  to_port                  = 3001
}
