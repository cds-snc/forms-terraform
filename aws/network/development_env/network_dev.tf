#
# VPC:
# Defines the network and subnets for the Forms service
# Provides no internet access
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
# Subnets:
# 3 private subnets
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

# We need to create the resource as a dummy output
resource "aws_subnet" "forms_public" {
  count = 0

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


