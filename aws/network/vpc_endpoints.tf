#
# VPC Endpoints:
# Allows for communication between the VPC and 
# AWS services that does not route over the internet.
#
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

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.forms.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  route_table_ids   = [aws_vpc.forms.main_route_table_id]
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.forms.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${var.region}.s3"
  route_table_ids   = [aws_vpc.forms.main_route_table_id]
}
