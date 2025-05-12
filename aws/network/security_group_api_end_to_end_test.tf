resource "aws_security_group" "api_end_to_end_test_lambda" {
  description = "API end to end test Lambda"
  name        = "api_end_to_end_test_lambda"
  vpc_id      = aws_vpc.forms.id
}

resource "aws_vpc_security_group_egress_rule" "local_lambda_to_idp" {
  description                  = "Egress from Lambda to IdP for local communication"
  security_group_id            = aws_security_group.api_end_to_end_test_lambda.id
  referenced_security_group_id = aws_security_group.idp_ecs.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}

// Using aws_security_group_rule instead of aws_vpc_security_group_egress_rule
// due to warning on https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "local_lambda_to_idp_ingress" {
  description              = "Ingress to IdP from Lambda for local communication"
  type                     = "ingress"
  security_group_id        = aws_security_group.idp_ecs.id
  source_security_group_id = aws_security_group.api_end_to_end_test_lambda.id
  protocol                 = "tcp"
  from_port                = 8080
  to_port                  = 8080
}

resource "aws_vpc_security_group_egress_rule" "local_lambda_to_api" {
  description                  = "Egress from Lambda to API for local communication"
  security_group_id            = aws_security_group.api_end_to_end_test_lambda.id
  referenced_security_group_id = aws_security_group.api_ecs.id
  ip_protocol                  = "tcp"
  from_port                    = 3001
  to_port                      = 3001
}

// Using aws_security_group_rule instead of aws_vpc_security_group_egress_rule
// due to warning on https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "local_lambda_to_api_ingress" {
  description              = "Ingress to API from Lambda for local communication"
  type                     = "ingress"
  security_group_id        = aws_security_group.api_ecs.id
  source_security_group_id = aws_security_group.api_end_to_end_test_lambda.id
  protocol                 = "tcp"
  from_port                = 3001
  to_port                  = 3001
}

// This allows the API end to end test lambda to invoke the Submission lambda
resource "aws_vpc_security_group_egress_rule" "https_from_api_end_to_end_test_to_private_link" {
  description       = "Egress to privatelink security group for HTTPS communication"
  security_group_id = aws_security_group.api_end_to_end_test_lambda.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

// This allows the API end to end test lambda to invoke the Submission lambda
//
// Using aws_security_group_rule instead of aws_vpc_security_group_egress_rule
// due to warning on https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
resource "aws_security_group_rule" "https_from_private_link_to_api_end_to_end_test" {
  description              = "Ingress from API end to end test security group for HTTPS communication"
  type                     = "ingress"
  security_group_id        = aws_security_group.privatelink.id
  source_security_group_id = aws_security_group.api_end_to_end_test_lambda.id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
}
