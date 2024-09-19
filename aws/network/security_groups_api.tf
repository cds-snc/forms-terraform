# ECS
resource "aws_security_group" "api_ecs" {
  description = "API ECS Tasks"
  name        = "api_ecs"
  vpc_id      = aws_vpc.forms.id
}

resource "aws_security_group_rule" "api_ecs_egress_internet" {
  description       = "Egress from API ECS task to internet (HTTPS)"
  type              = "egress"
  to_port           = 443
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.api_ecs.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "api_ecs_egress_privatelink" {
  description              = "Egress from API ECS task to PrivateLink endpoints"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.api_ecs.id
  source_security_group_id = aws_security_group.privatelink.id
}

# Load balancer
resource "aws_security_group_rule" "api_ecs_ingress_lb" {
  description              = "Ingress from load balancer to API ECS task"
  type                     = "ingress"
  from_port                = 3001
  to_port                  = 3001
  protocol                 = "tcp"
  security_group_id        = aws_security_group.api_ecs.id
  source_security_group_id = aws_security_group.forms_load_balancer.id
}

resource "aws_security_group_rule" "lb_egress_api_ecs" {
  description              = "Egress from load balancer to API ECS task"
  type                     = "egress"
  from_port                = 3001
  to_port                  = 3001
  protocol                 = "tcp"
  security_group_id        = aws_security_group.forms_load_balancer.id
  source_security_group_id = aws_security_group.api_ecs.id
}

# Database
resource "aws_security_group_rule" "db_ingress_api_ecs" {
  description              = "Ingress to database from API ECS task"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.forms_database.id
  source_security_group_id = aws_security_group.api_ecs.id
}

resource "aws_security_group_rule" "api_ecs_egress_db" {
  description              = "Egress from API ECS task to database"
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.api_ecs.id
  source_security_group_id = aws_security_group.forms_database.id
}

# Redis
resource "aws_security_group_rule" "redis_ingress_api_ecs" {
  description              = "Ingress to Redis from API ECS task"
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.forms_redis.id
  source_security_group_id = aws_security_group.api_ecs.id
}

resource "aws_security_group_rule" "api_ecs_egress_redis" {
  description              = "Egress from API ECS task to Redis"
  type                     = "egress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.api_ecs.id
  source_security_group_id = aws_security_group.forms_redis.id
}
