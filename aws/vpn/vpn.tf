resource "aws_ec2_client_vpn_endpoint" "development" {
  description            = "development-environment-connection"
  server_certificate_arn = aws_acm_certificate.vpn.arn
  client_cidr_block      = cidrsubnet(var.vpc_cidr_block, 4, 7)
  split_tunnel           = true
  vpc_id                 = var.vpc_id
  security_group_ids     = [var.ecs_security_group_id]


  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.vpn.arn
  }

  connection_log_options {
    enabled = false
  }
}

resource "aws_ec2_client_vpn_network_association" "development" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.development.id
  subnet_id              = var.private_subnet_ids[0]
}

resource "aws_ec2_client_vpn_authorization_rule" "example" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.development.id
  target_network_cidr    = var.vpc_cidr_block
  authorize_all_groups   = true
}