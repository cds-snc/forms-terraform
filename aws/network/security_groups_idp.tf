# ECS
resource "aws_security_group" "idp_ecs" {
  description = "Zitadel IdP ECS Tasks"
  name        = "idp_ecs"
  vpc_id      = aws_vpc.forms.id
}

resource "aws_security_group_rule" "idp_ecs_egress_internet" {
  description       = "Egress from Zitadel IdP ECS task to internet (HTTPS)"
  type              = "egress"
  to_port           = 443
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.idp_ecs.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "idp_ecs_egress_smtp_tls" {
  description       = "Egress from Zitadel IdP ECS task to SMTP"
  type              = "egress"
  to_port           = 465
  from_port         = 465
  protocol          = "tcp"
  security_group_id = aws_security_group.idp_ecs.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "idp_ecs_egress_privatelink" {
  description              = "Egress from Zitadel IdP ECS task to PrivateLink endpoints"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.idp_ecs.id
  source_security_group_id = aws_security_group.privatelink.id
}

resource "aws_security_group_rule" "idp_ecs_ingress_lb" {
  description              = "Ingress from load balancer to Zitadel IdP ECS task"
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.idp_ecs.id
  source_security_group_id = aws_security_group.idp_lb.id
}

# Load balancer
resource "aws_security_group" "idp_lb" {
  name        = "idp_lb"
  description = "Zitadel IdP load balancer"
  vpc_id      = aws_vpc.forms.id
}

resource "aws_security_group_rule" "idp_lb_ingress_internet_http" {
  # checkov:skip=CKV_AWS_260: port 80 is required for the redirect to HTTPS (443) done by the load balancer
  description       = "Ingress from internet to the Zitadel IdP load balancer (HTTP)"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.idp_lb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "idp_lb_ingress_internet_https" {
  description       = "Ingress from internet to the Zitadel IdP load balancer (HTTPS)"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.idp_lb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "idp_lb_egress_ecs" {
  description              = "Egress from load balancer to Zitadel IdP ECS task"
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.idp_lb.id
  source_security_group_id = aws_security_group.idp_ecs.id
}

# Database
resource "aws_security_group" "idp_db" {
  name        = "idp_db"
  description = "Zitadel IdP database"
  vpc_id      = aws_vpc.forms.id
}

resource "aws_security_group_rule" "idp_db_ingress_ecs" {
  description              = "Ingress to database from Zitadel IdP ECS task"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.idp_db.id
  source_security_group_id = aws_security_group.idp_ecs.id
}

resource "aws_security_group_rule" "idp_ecs_egress_db" {
  description              = "Egress from Zitadel IdP ECS task to database"
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.idp_ecs.id
  source_security_group_id = aws_security_group.idp_db.id
}

resource "aws_security_group_rule" "idp_db_egress_privatelink" {
  description              = "Egress from Zitadel IdP database to PrivateLink endpoints"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.idp_db.id
  source_security_group_id = aws_security_group.privatelink.id
}

// Allow API end to end test local communication from Lambda to IdP

resource "aws_vpc_security_group_ingress_rule" "local_lambda_to_idp" {
  description                  = "Ingress to IdP from Lambda for local communication"
  security_group_id            = aws_security_group.idp_ecs.id
  referenced_security_group_id = aws_security_group.lambda.id
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}
