###
# AWS VPC
###

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "forms" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name                  = var.vpc_name
    (var.billing_tag_key) = var.billing_tag_value
  }
}

###
# AWS VPC Privatelink Endpoints
###

resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = aws_vpc.forms.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.sqs"
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.privatelink.id
  ]
  subnet_ids = aws_subnet.forms_private.*.id
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.forms.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  route_table_ids   = [aws_vpc.forms.main_route_table_id]
}

resource "aws_vpc_endpoint" "lambda" {
  vpc_id              = aws_vpc.forms.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.lambda"
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.privatelink.id,
  ]
  subnet_ids = data.aws_subnet_ids.lambda_endpoint_available.ids
}

resource "aws_vpc_endpoint" "ecr-dkr" {
  vpc_id              = aws_vpc.forms.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.privatelink.id,
  ]
  subnet_ids = data.aws_subnet_ids.ecr_endpoint_available.ids
}

resource "aws_vpc_endpoint" "ecr-api" {
  vpc_id              = aws_vpc.forms.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.privatelink.id,
  ]
  subnet_ids = data.aws_subnet_ids.ecr_endpoint_available.ids
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id              = aws_vpc.forms.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.kms"
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.privatelink.id,
  ]
  subnet_ids = aws_subnet.forms_private.*.id
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.forms.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.privatelink.id,
  ]
  subnet_ids = aws_subnet.forms_private.*.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.forms.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${var.region}.s3"
  route_table_ids   = [aws_vpc.forms.main_route_table_id]
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.forms.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.logs"
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.privatelink.id,
  ]
  subnet_ids = aws_subnet.forms_private.*.id
}

resource "aws_vpc_endpoint" "monitoring" {
  vpc_id              = aws_vpc.forms.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.monitoring"
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.privatelink.id,
  ]
  subnet_ids = aws_subnet.forms_private.*.id
}
resource "aws_vpc_endpoint" "rds" {
  vpc_id              = aws_vpc.forms.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.rds-data"
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.privatelink.id,
  ]
  subnet_ids = aws_subnet.forms_private.*.id
}

###
# AWS Internet Gateway
###

resource "aws_internet_gateway" "forms" {
  vpc_id = aws_vpc.forms.id

  tags = {
    Name                  = var.vpc_name
    (var.billing_tag_key) = var.billing_tag_value
  }
}

###
# AWS Subnets
###

resource "aws_subnet" "forms_private" {
  count = 3

  vpc_id            = aws_vpc.forms.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 4, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name                  = "Private Subnet 0${count.index + 1}"
    (var.billing_tag_key) = var.billing_tag_value
    Access                = "private"
  }
}

resource "aws_subnet" "forms_public" {
  count = 3

  vpc_id            = aws_vpc.forms.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 4, count.index + 3)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name                  = "Public Subnet 0${count.index + 1}"
    (var.billing_tag_key) = var.billing_tag_value
    Access                = "public"
  }
}

data "aws_subnet_ids" "ecr_endpoint_available" {
  vpc_id = aws_vpc.forms.id
  filter {
    name   = "tag:Access"
    values = ["private"]
  }
  filter {
    name   = "availability-zone"
    values = ["ca-central-1a", "ca-central-1b"]
  }
  depends_on = [aws_subnet.forms_private]
}

data "aws_subnet_ids" "lambda_endpoint_available" {
  vpc_id = aws_vpc.forms.id
  filter {
    name   = "tag:Access"
    values = ["private"]
  }
  filter {
    name   = "availability-zone"
    values = ["ca-central-1a", "ca-central-1b"]
  }
  depends_on = [aws_subnet.forms_private]
}

###
# AWS NAT GW
###

resource "aws_eip" "forms_natgw" {
  count      = 3
  depends_on = [aws_internet_gateway.forms]

  vpc = true

  tags = {
    Name                  = "${var.vpc_name} NAT GW ${count.index}"
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_nat_gateway" "forms" {
  count      = 3
  depends_on = [aws_internet_gateway.forms]

  allocation_id = aws_eip.forms_natgw.*.id[count.index]
  subnet_id     = aws_subnet.forms_public.*.id[count.index]

  tags = {
    Name                  = "${var.vpc_name} NAT GW"
    (var.billing_tag_key) = var.billing_tag_value
  }
}



###
# AWS Routes
###

resource "aws_route_table" "forms_public_subnet" {
  vpc_id = aws_vpc.forms.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.forms.id
  }

  tags = {
    Name                  = "Public Subnet Route Table"
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_route_table_association" "forms" {
  count = 3

  subnet_id      = aws_subnet.forms_public.*.id[count.index]
  route_table_id = aws_route_table.forms_public_subnet.id
}

resource "aws_route_table" "forms_private_subnet" {
  count = 3

  vpc_id = aws_vpc.forms.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.forms.*.id[count.index]
  }

  tags = {
    Name                  = "Private Subnet Route Table ${count.index}"
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_route_table_association" "forms_private_route" {
  count = 3

  subnet_id      = aws_subnet.forms_private.*.id[count.index]
  route_table_id = aws_route_table.forms_private_subnet.*.id[count.index]
}

###
# AWS Security Groups
###

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.forms.id
}

resource "aws_security_group" "forms" {
  name        = "forms"
  description = "Ingress - Forms"
  vpc_id      = aws_vpc.forms.id

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
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
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:AWS008
  }
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:AWS008
  }

  egress {
    protocol    = "tcp"
    from_port   = 3000
    to_port     = 3000
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_security_group" "forms_egress" {
  name        = "egress-anywhere"
  description = "Egress - Forms External Services"
  vpc_id      = aws_vpc.forms.id

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_security_group_rule" "forms_egress_notify" {
  description       = "Security group rule for Forms Notify egress"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.forms_egress.id
  cidr_blocks       = ["0.0.0.0/0"] #tfsec:ignore:AWS007
}

resource "aws_security_group" "privatelink" {
  name        = "privatelink"
  description = "privatelink endpoints"
  vpc_id      = aws_vpc.forms.id

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
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
  }
}

###
# AWS Network ACL
###

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
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  // See https://www.terraform.io/docs/providers/aws/r/default_network_acl.html#managing-subnets-in-the-default-network-acl
  lifecycle {
    ignore_changes = [subnet_ids]
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}
