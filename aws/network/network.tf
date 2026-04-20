#
# VPC:
# Defines the network and subnets for the Forms service
#
locals {
  subnetCount = 3
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "forms" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

#
# Internet Gateway:
# Allow VPC resources to communicate with the internet
#
resource "aws_internet_gateway" "forms" {
  vpc_id = aws_vpc.forms.id

  tags = {
    Name = var.vpc_name
  }
}

#
# Subnets:
# 3 public, 3 private subnets, 3 firewall 
#

resource "aws_subnet" "forms_private" {
  count = local.subnetCount

  vpc_id            = aws_vpc.forms.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 4, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name   = "Private Subnet 0${count.index + 1}"
    Access = "private"
  }
}

resource "aws_subnet" "forms_public" {
  count = local.subnetCount

  vpc_id            = aws_vpc.forms.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 4, count.index + local.subnetCount)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name   = "Public Subnet 0${count.index + 1}"
    Access = "public"
  }
}

resource "aws_subnet" "firewall" {
  count             = local.subnetCount
  vpc_id            = aws_vpc.forms.id
  cidr_block        = cidrsubnet(cidrsubnet(var.vpc_cidr_block, 4, local.subnetCount * 2 + 1), 8, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name   = "Firewall Subnet"
    Access = "public"
  }
}

data "aws_subnets" "ecr_endpoint_available" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.forms.id]
  }
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

data "aws_subnets" "lambda_endpoint_available" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.forms.id]
  }
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

#
# NAT Gateway
# Allows private resources to access the internet
#
resource "aws_nat_gateway" "forms" {
  count = local.subnetCount

  allocation_id = aws_eip.forms_natgw.*.id[count.index]
  subnet_id     = aws_subnet.forms_public.*.id[count.index]

  tags = {
    Name = "${var.vpc_name} NAT GW"
  }

  depends_on = [aws_internet_gateway.forms]
}

resource "aws_eip" "forms_natgw" {
  # checkov:skip=CKV2_AWS_19: False positive.  All EIP's are associated to Nat Gateways
  count  = local.subnetCount
  domain = "vpc"

  tags = {
    Name = "${var.vpc_name} NAT GW ${count.index}"
  }
}

#
# IG Ingress Route
#

resource "aws_route_table" "ig" {
  vpc_id = aws_vpc.forms.id

  tags = {
    Name = "Internet Gateway Ingress Route Table"
  }
}

resource "aws_route" "ig" {
  count = local.subnetCount

  route_table_id         = aws_route_table.ig.id
  destination_cidr_block = aws_subnet.forms_public[count.index].cidr_block
  vpc_endpoint_id        = local.networkfirewall_endpoints[element(data.aws_availability_zones.available.names, count.index)]
}

resource "aws_route_table_association" "ig" {
  gateway_id     = aws_internet_gateway.forms.id
  route_table_id = aws_route_table.ig.id
}


#
# Firewall Routes
# 

resource "aws_route_table" "firewall" {
  vpc_id = aws_vpc.forms.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.forms.id
  }

  tags = {
    Name = "Firewall Inspection Route Table"
  }
}

resource "aws_route_table_association" "firewall" {
  count          = local.subnetCount
  subnet_id      = aws_subnet.firewall.*.id[count.index]
  route_table_id = aws_route_table.firewall.id
}


#
# Public Routes
#


resource "aws_route_table" "forms_public_subnet" {
  count  = local.subnetCount
  vpc_id = aws_vpc.forms.id

  route {
    cidr_block      = "0.0.0.0/0"
    vpc_endpoint_id = local.networkfirewall_endpoints[element(data.aws_availability_zones.available.names, count.index)]
  }

  tags = {
    Name = "Public Subnet Route Table ${count.index + 1}"
  }
}

resource "aws_route_table_association" "forms" {
  count = local.subnetCount

  subnet_id      = aws_subnet.forms_public.*.id[count.index]
  route_table_id = aws_route_table.forms_public_subnet.*.id[count.index]
}

#
# Private Routes
#


resource "aws_route_table" "forms_private_subnet" {
  count = local.subnetCount

  vpc_id = aws_vpc.forms.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.forms.*.id[count.index]
  }

  tags = {
    Name = "Private Subnet Route Table ${count.index + 1}"
  }
}

resource "aws_route_table_association" "forms_private_route" {
  count = local.subnetCount

  subnet_id      = aws_subnet.forms_private.*.id[count.index]
  route_table_id = aws_route_table.forms_private_subnet.*.id[count.index]
}


#
# Local DNS Namespace
#

resource "aws_service_discovery_private_dns_namespace" "ecs_local" {
  name        = "ecs.local"
  description = "DNS namespace used to provide service discovery for ECS services to allow for local communication (within VPC)"
  vpc         = aws_vpc.forms.id
}
