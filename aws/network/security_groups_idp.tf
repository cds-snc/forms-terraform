# ECS
resource "aws_security_group" "idp_ecs" {
  count = var.feature_flag_idp ? 1 : 0

  description = "Zitadel IdP ECS Tasks"
  name        = "idp_ecs"
  vpc_id      = aws_vpc.forms.id
}

resource "aws_security_group_rule" "idp_ecs_egress_internet" {
  count = var.feature_flag_idp ? 1 : 0

  description       = "Egress from Zitadel IdP ECS task to internet (HTTPS)"
  type              = "egress"
  to_port           = 443
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.idp_ecs[0].id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "idp_ecs_egress_smtp_tls" {
  count = var.feature_flag_idp ? 1 : 0

  description       = "Egress from Zitadel IdP ECS task to SMTP"
  type              = "egress"
  to_port           = 465
  from_port         = 465
  protocol          = "tcp"
  security_group_id = aws_security_group.idp_ecs[0].id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "idp_ecs_egress_privatelink" {
  count = var.feature_flag_idp ? 1 : 0

  description              = "Egress from Zitadel IdP ECS task to PrivateLink endpoints"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.idp_ecs[0].id
  source_security_group_id = aws_security_group.privatelink.id
}

resource "aws_security_group_rule" "idp_ecs_ingress_lb" {
  count = var.feature_flag_idp ? 1 : 0

  description              = "Ingress from load balancer to Zitadel IdP ECS task"
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.idp_ecs[0].id
  source_security_group_id = aws_security_group.idp_lb[0].id
}

# Load balancer
resource "aws_security_group" "idp_lb" {
  count = var.feature_flag_idp ? 1 : 0

  name        = "idp_lb"
  description = "Zitadel IdP load balancer"
  vpc_id      = aws_vpc.forms.id
}

resource "aws_security_group_rule" "idp_lb_ingress_internet_http" {
  # checkov:skip=CKV_AWS_260: port 80 is required for the redirect to HTTPS (443) done by the load balancer
  count = var.feature_flag_idp ? 1 : 0

  description       = "Ingress from internet to the Zitadel IdP load balancer (HTTP)"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.idp_lb[0].id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "idp_lb_ingress_internet_https" {
  count = var.feature_flag_idp ? 1 : 0

  description       = "Ingress from internet to the Zitadel IdP load balancer (HTTPS)"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.idp_lb[0].id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "idp_lb_egress_ecs" {
  count = var.feature_flag_idp ? 1 : 0

  description              = "Egress from load balancer to Zitadel IdP ECS task"
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.idp_lb[0].id
  source_security_group_id = aws_security_group.idp_ecs[0].id
}

# Database
resource "aws_security_group" "idp_db" {
  count = var.feature_flag_idp ? 1 : 0

  name        = "idp_db"
  description = "Zitadel IdP database"
  vpc_id      = aws_vpc.forms.id
}

resource "aws_security_group_rule" "idp_db_ingress_ecs" {
  count = var.feature_flag_idp ? 1 : 0

  description              = "Ingress to database from Zitadel IdP ECS task"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.idp_db[0].id
  source_security_group_id = aws_security_group.idp_ecs[0].id
}

resource "aws_security_group_rule" "idp_ecs_egress_db" {
  count = var.feature_flag_idp ? 1 : 0

  description              = "Egress from Zitadel IdP ECS task to database"
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.idp_ecs[0].id
  source_security_group_id = aws_security_group.idp_db[0].id
}

resource "aws_security_group_rule" "idp_db_egress_privatelink" {
  count = var.feature_flag_idp ? 1 : 0

  description              = "Egress from Zitadel IdP database to PrivateLink endpoints"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.idp_db[0].id
  source_security_group_id = aws_security_group.privatelink.id
}
