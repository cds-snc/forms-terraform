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

resource "aws_vpc_security_group_ingress_rule" "database_to_code_build" {
  description                  = "Ingress to GC Forms database from Code Build"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.forms_database.id
  referenced_security_group_id = aws_security_group.code_build.id
}

resource "aws_vpc_security_group_egress_rule" "code_build_to_database" {
  description                  = "Egress from Code Build to GC Forms database"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  security_group_id            = aws_security_group.code_build.id
  referenced_security_group_id = aws_security_group.forms_database.id
}
