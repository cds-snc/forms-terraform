# SG for Athena Lambda Connector 
resource "aws_security_group" "connector_db" {
  name        = "connector_db"
  description = "For the Lambda RDS connector"
  vpc_id      = aws_vpc.forms.id
}

resource "aws_security_group_rule" "connector_ingress_rds" {
  description              = "Ingress to database from lambda connector"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.forms_database.id
  source_security_group_id = aws_security_group.connector_db.id
}

resource "aws_security_group_rule" "connector_egress_rds" {

  description              = "Egress from lambda connector to database"
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.connector_db.id
  source_security_group_id = aws_security_group.forms_database.id
}

resource "aws_security_group_rule" "connector_db_egress_privatelink" {

  description              = "Egress from lambda connector to PrivateLink endpoints"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.connector_db.id
  source_security_group_id = aws_security_group.privatelink.id
}

resource "aws_security_group_rule" "privatelink_connector_db_ingress" {
  description              = "Security group rule for lambda connector ingress"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.privatelink.id
  source_security_group_id = aws_security_group.connector_db.id
}