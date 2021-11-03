#
# Security Groups
#
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.forms.id

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_security_group" "forms" {
  name        = "forms"
  description = "Ingress - Forms"
  vpc_id      = aws_vpc.forms.id

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
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
  name        = "forms-load-balancer"
  description = "Ingress - forms Load Balancer"
  vpc_id      = aws_vpc.forms.id

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 3000
    to_port     = 3000
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_security_group" "forms_egress" {
  name        = "egress-anywhere"
  description = "Egress - Forms External Services"
  vpc_id      = aws_vpc.forms.id

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_security_group_rule" "forms_egress_notify" {
  description       = "Security group rule for Forms Notify egress"
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

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
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


# Allow traffic from the app and from the lambdas
resource "aws_security_group" "forms_database" {
  name        = "forms-database"
  description = "Ingress - Forms Database"
  vpc_id      = aws_vpc.forms.id

  ingress {
    protocol  = "tcp"
    from_port = 5432
    to_port   = 5432
    security_groups = [
      aws_security_group.forms.id,
    ]
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

# Allow traffic from the app
resource "aws_security_group" "forms_redis" {
  name        = "forms-redis"
  description = "Ingress - Forms Redis"
  vpc_id      = aws_vpc.forms.id

  ingress {
    protocol  = "tcp"
    from_port = 6379
    to_port   = 6379
    security_groups = [
      aws_security_group.forms.id,
    ]
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
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

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}
