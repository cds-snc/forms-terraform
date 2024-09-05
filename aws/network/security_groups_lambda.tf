resource "aws_security_group" "lambda_nagware" {
  description = "Lambda Nagware"
  name        = "lambda_nagware"
  vpc_id      = aws_vpc.forms.id
}

resource "aws_security_group_rule" "lambda_nagware_egress_internet" {
  description       = "Egress to the internet from Nagware Lambda function"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda_nagware.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Redis
resource "aws_security_group_rule" "redis_ingress_lambda_nagware" {
  description              = "Ingress to Redis from Nagware Lambda function"
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.forms_redis.id
  source_security_group_id = aws_security_group.lambda_nagware.id
}

resource "aws_security_group_rule" "lambda_nagware_egress_redis" {
  description              = "Egress from Nagware Lambda function to Redis"
  type                     = "egress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda_nagware.id
  source_security_group_id = aws_security_group.forms_redis.id
}
