#
# VPC:
# Defines the network and subnets for the Forms service
#
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
# 3 public and 3 private subnets
#
resource "aws_subnet" "forms_private" {
  count = 3

  vpc_id            = aws_vpc.forms.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 4, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name   = "Private Subnet 0${count.index + 1}"
    Access = "private"
  }
}

resource "aws_subnet" "forms_public" {
  count = 3

  vpc_id            = aws_vpc.forms.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 4, count.index + 3)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name   = "Public Subnet 0${count.index + 1}"
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
  count = 3

  allocation_id = aws_eip.forms_natgw.*.id[count.index]
  subnet_id     = aws_subnet.forms_public.*.id[count.index]

  tags = {
    Name = "${var.vpc_name} NAT GW"
  }

  depends_on = [aws_internet_gateway.forms]
}

resource "aws_eip" "forms_natgw" {
  # checkov:skip=CKV2_AWS_19: False positive.  All EIP's are associated to Nat Gateways
  count  = 3
  domain = "vpc"

  tags = {
    Name = "${var.vpc_name} NAT GW ${count.index}"
  }
}

#
# Routes
#
resource "aws_route_table" "forms_public_subnet" {
  vpc_id = aws_vpc.forms.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.forms.id
  }

  tags = {
    Name = "Public Subnet Route Table"
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
    Name = "Private Subnet Route Table ${count.index}"
  }
}

resource "aws_route_table_association" "forms_private_route" {
  count = 3

  subnet_id      = aws_subnet.forms_private.*.id[count.index]
  route_table_id = aws_route_table.forms_private_subnet.*.id[count.index]
}

resource "aws_service_discovery_private_dns_namespace" "ecs_local" {
  name        = "ecs.local"
  description = "DNS namespace used to provide service discovery for ECS services to allow for local communication (within VPC)"
  vpc         = aws_vpc.forms.id
}
