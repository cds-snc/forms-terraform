# ECS
resource "aws_security_group" "api_ecs" {
  count = var.feature_flag_api ? 1 : 0

  description = "API ECS Tasks"
  name        = "api_ecs"
  vpc_id      = aws_vpc.forms.id
}

resource "aws_security_group_rule" "api_ecs_egress_internet" {
  count = var.feature_flag_api ? 1 : 0

  description       = "Egress from API ECS task to internet (HTTPS)"
  type              = "egress"
  to_port           = 443
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.api_ecs[0].id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "api_ecs_egress_privatelink" {
  count = var.feature_flag_api ? 1 : 0

  description              = "Egress from API ECS task to PrivateLink endpoints"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.api_ecs[0].id
  source_security_group_id = aws_security_group.privatelink.id
}

# Load balancer
resource "aws_security_group_rule" "api_ecs_ingress_lb" {
  count = var.feature_flag_api ? 1 : 0

  description              = "Ingress from load balancer to API ECS task"
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.api_ecs[0].id
  source_security_group_id = aws_security_group.forms_load_balancer.id
}

resource "aws_security_group_rule" "lb_egress_api_ecs" {
  count = var.feature_flag_api ? 1 : 0

  description              = "Egress from load balancer to API ECS task"
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.forms_load_balancer.id
  source_security_group_id = aws_security_group.api_ecs[0].id
}

# Database
resource "aws_security_group_rule" "db_ingress_api_ecs" {
  count = var.feature_flag_api ? 1 : 0

  description              = "Ingress to database from API ECS task"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.forms_database.id
  source_security_group_id = aws_security_group.api_ecs[0].id
}

resource "aws_security_group_rule" "api_ecs_egress_db" {
  count = var.feature_flag_api ? 1 : 0

  description              = "Egress from API ECS task to database"
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.api_ecs[0].id
  source_security_group_id = aws_security_group.forms_database.id
}
