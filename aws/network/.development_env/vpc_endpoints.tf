locals {
  private_subnet_ids = [aws_subnet.forms_private[0].id]
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

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.forms.id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  private_dns_enabled = true
  security_group_ids = [
    aws_security_group.privatelink.id,
  ]
  subnet_ids = local.private_subnet_ids
}