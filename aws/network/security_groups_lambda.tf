#
# Nagware
#
resource "aws_security_group" "lambda" {
  description = "Lambdas"
  name        = "lambda"
  vpc_id      = aws_vpc.forms.id
}

# Internet

resource "aws_vpc_security_group_ingress_rule" "privatelink" {
  description                  = "Security group rule for Nagware Lambda function ingress"
  security_group_id            = aws_security_group.lambda.id
  referenced_security_group_id = aws_security_group.privatelink.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443

}

resource "aws_vpc_security_group_egress_rule" "privatelink" {
  description       = "Egress to the internet from Nagware Lambda function"
  security_group_id = aws_security_group.lambda.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}


# Redis
resource "aws_vpc_security_group_ingress_rule" "redis" {
  description                  = "Ingress to Redis from lambda"
  security_group_id            = aws_security_group.forms_redis.id
  referenced_security_group_id = aws_security_group.lambda.id
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379

}

# RDS
resource "aws_vpc_security_group_ingress_rule" "rds" {
  description                  = "Ingress to database from lambda"
  security_group_id            = aws_security_group.forms_database.id
  referenced_security_group_id = aws_security_group.lambda.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}


#
# Athena connector
#
resource "aws_security_group" "connector_db" {
  name        = "connector_db"
  description = "For the Lambda RDS connector"
  vpc_id      = aws_vpc.forms.id
}

# Database
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

# PrivateLink
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

resource "aws_security_group_rule" "s3_gateway_connector_db_egress" {
  description       = "Security group rule for Lambda RDS Connector S3 egress through VPC endpoints"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.connector_db.id
  prefix_list_ids = [
    aws_vpc_endpoint.s3.prefix_list_id
  ]
}
