resource "aws_security_group" "code_build" {
  description = "Code Build"
  name        = "code_build"
  vpc_id      = aws_vpc.forms.id
}

# Internet

resource "aws_vpc_security_group_ingress_rule" "code_build_private_link" {
  description                  = "Security group rule for Code build ingress"
  security_group_id            = aws_security_group.privatelink.id
  referenced_security_group_id = aws_security_group.code_build.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443

}

resource "aws_vpc_security_group_egress_rule" "code_build_internet" {
  description       = "Egress to the internet from Code Build"
  security_group_id = aws_security_group.code_build.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

