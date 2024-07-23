#
# Security Groups
#

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.forms.id
}

resource "aws_security_group" "forms" {
  name        = "forms"
  description = "Ingress - Forms"
  vpc_id      = aws_vpc.forms.id
}

resource "aws_security_group_rule" "forms_ingress_alb" {
  description              = "Security group rule for Forms Ingress ALB"
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.forms.id
  source_security_group_id = aws_security_group.forms_load_balancer.id
}

resource "aws_security_group_rule" "forms_egress_privatelink" {
  description              = "Security group rule for Forms egress through privatelink"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.forms.id
  source_security_group_id = aws_security_group.privatelink.id
}

resource "aws_security_group_rule" "forms_egress_database" {
  description              = "Security group rule for Forms DB egress to Database"
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.forms.id
  source_security_group_id = aws_security_group.forms_database.id
}

resource "aws_security_group_rule" "forms_egress_redis" {
  description              = "Security group rule for Forms DB egress to Redis"
  type                     = "egress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.forms.id
  source_security_group_id = aws_security_group.forms_redis.id
}

resource "aws_security_group" "forms_load_balancer" {
  # checkov:skip=CKV_AWS_260: Ingress from 0.0.0.0:0 to port 80 is required by the load balancer to redirect users from HTTP to HTTPS
  name        = "forms-load-balancer"
  description = "Ingress - forms Load Balancer"
  vpc_id      = aws_vpc.forms.id
}

resource "aws_security_group_rule" "forms_lb_ingress_internet_443" {
  description       = "Ingress to the Load Balancer from the internet on port 443"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.forms_load_balancer.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "forms_lb_ingress_internet_80" {
  # checkov:skip=CKV_AWS_260: Ingress from 0.0.0.0:0 to port 80 is required by the load balancer to redirect users from HTTP to HTTPS
  description       = "Ingress to the Load Balancer from the internet on port 80"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.forms_load_balancer.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# TODO: scope this down to the app ECS task only
resource "aws_security_group_rule" "forms_lb_egress_vpc" {
  description       = "Egress from the Load Balancer to the VPC"
  type              = "egress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  security_group_id = aws_security_group.forms_load_balancer.id
  cidr_blocks       = [var.vpc_cidr_block]
}

# TODO: remove once these have applied in Production
# These are being converted to standalone SG rules to prevent rule flip-flops.
import {
  to = aws_security_group_rule.forms_lb_ingress_internet_443
  id = "${aws_security_group.forms_load_balancer.id}_ingress_tcp_443_443_0.0.0.0/0"
}

import {
  to = aws_security_group_rule.forms_lb_ingress_internet_80
  id = "${aws_security_group.forms_load_balancer.id}_ingress_tcp_80_80_0.0.0.0/0"
}

import {
  to = aws_security_group_rule.forms_lb_egress_vpc
  id = "${aws_security_group.forms_load_balancer.id}_egress_tcp_3000_3000_${var.vpc_cidr_block}"
}

resource "aws_security_group" "forms_egress" {
  name        = "egress-anywhere"
  description = "Egress - Forms External Services"
  vpc_id      = aws_vpc.forms.id
}

resource "aws_security_group_rule" "forms_external_auth" {
  description       = "Security group rule for Forms app access to the internet for external authentication"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.forms_egress.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "privatelink" {
  name        = "privatelink"
  description = "privatelink endpoints"
  vpc_id      = aws_vpc.forms.id
}

resource "aws_security_group_rule" "privatelink_forms_ingress" {
  description              = "Security group rule for Forms ingress"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.privatelink.id
  source_security_group_id = aws_security_group.forms.id
}

resource "aws_security_group_rule" "privatelink_idp_ecs_ingress" {
  count = var.feature_flag_idp ? 1 : 0

  description              = "Security group rule for Zitadel IdP ECS task ingress"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.privatelink.id
  source_security_group_id = aws_security_group.idp_ecs[0].id
}

resource "aws_security_group_rule" "privatelink_idp_db_ingress" {
  count = var.feature_flag_idp ? 1 : 0

  description              = "Security group rule for Zitadel IdP database ingress"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.privatelink.id
  source_security_group_id = aws_security_group.idp_db[0].id
}

resource "aws_security_group_rule" "privatelink_api_ecs_ingress" {
  count = var.feature_flag_api ? 1 : 0

  description              = "Security group rule for API ECS task ingress"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.privatelink.id
  source_security_group_id = aws_security_group.api_ecs[0].id
}

# Allow traffic from the app and from the lambdas
resource "aws_security_group" "forms_database" {
  name        = "forms-database"
  description = "Ingress - Forms Database"
  vpc_id      = aws_vpc.forms.id
}

resource "aws_security_group_rule" "forms_database_ingress" {
  description              = "Security group rule for Forms Database ingress"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.forms_database.id
  source_security_group_id = aws_security_group.forms.id
}


# Allow traffic from the app
resource "aws_security_group" "forms_redis" {
  name        = "forms-redis"
  description = "Ingress - Forms Redis"
  vpc_id      = aws_vpc.forms.id
}

resource "aws_security_group_rule" "forms_redis_ingress" {
  description              = "Security group rule for Forms Database ingress"
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.forms_redis.id
  source_security_group_id = aws_security_group.forms.id
}

#
# Network ACL
# Blocks SSH/RDP ingress ports and allows all other traffic
#
resource "aws_default_network_acl" "forms" {
  default_network_acl_id = aws_vpc.forms.default_network_acl_id

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 3389
    to_port    = 3389
  }

  ingress {
    protocol   = -1
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 400
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_network_acl#managing-subnets-in-a-default-network-acl
  lifecycle {
    ignore_changes = [subnet_ids]
  }
}
