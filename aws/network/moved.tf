moved {
  from = aws_security_group.api_ecs[0]
  to   = aws_security_group.api_ecs
}

moved {
  from = aws_security_group_rule.api_ecs_egress_internet[0]
  to   = aws_security_group_rule.api_ecs_egress_internet
}

moved {
  from = aws_security_group_rule.api_ecs_egress_privatelink[0]
  to   = aws_security_group_rule.api_ecs_egress_privatelink
}

moved {
  from = aws_security_group_rule.api_ecs_ingress_lb[0]
  to   = aws_security_group_rule.api_ecs_ingress_lb
}

moved {
  from = aws_security_group_rule.lb_egress_api_ecs[0]
  to   = aws_security_group_rule.lb_egress_api_ecs
}

moved {
  from = aws_security_group_rule.db_ingress_api_ecs[0]
  to   = aws_security_group_rule.db_ingress_api_ecs
}

moved {
  from = aws_security_group_rule.api_ecs_egress_db[0]
  to   = aws_security_group_rule.api_ecs_egress_db
}

moved {
  from = aws_security_group_rule.redis_ingress_api_ecs[0]
  to   = aws_security_group_rule.redis_ingress_api_ecs
}

moved {
  from = aws_security_group_rule.api_ecs_egress_redis[0]
  to   = aws_security_group_rule.api_ecs_egress_redis
}

moved {
  from = aws_security_group_rule.privatelink_idp_ecs_ingress[0]
  to   = aws_security_group_rule.privatelink_idp_ecs_ingress
}

moved {
  from = aws_security_group_rule.privatelink_idp_db_ingress[0]
  to   = aws_security_group_rule.privatelink_idp_db_ingress
}

moved {
  from = aws_security_group_rule.privatelink_api_ecs_ingress[0]
  to   = aws_security_group_rule.privatelink_api_ecs_ingress
}

moved {
  from = aws_security_group.idp_ecs[0]
  to   = aws_security_group.idp_ecs
}

moved {
  from = aws_security_group_rule.idp_ecs_egress_internet[0]
  to   = aws_security_group_rule.idp_ecs_egress_internet
}

moved {
  from = aws_security_group_rule.idp_ecs_egress_smtp_tls[0]
  to   = aws_security_group_rule.idp_ecs_egress_smtp_tls
}

moved {
  from = aws_security_group_rule.idp_ecs_egress_privatelink[0]
  to   = aws_security_group_rule.idp_ecs_egress_privatelink
}

moved {
  from = aws_security_group_rule.idp_ecs_ingress_lb[0]
  to   = aws_security_group_rule.idp_ecs_ingress_lb
}

moved {
  from = aws_security_group.idp_lb[0]
  to   = aws_security_group.idp_lb
}

moved {
  from = aws_security_group_rule.idp_lb_ingress_internet_http[0]
  to   = aws_security_group_rule.idp_lb_ingress_internet_http
}

moved {
  from = aws_security_group_rule.idp_lb_ingress_internet_https[0]
  to   = aws_security_group_rule.idp_lb_ingress_internet_https
}

moved {
  from = aws_security_group_rule.idp_lb_egress_ecs[0]
  to   = aws_security_group_rule.idp_lb_egress_ecs
}

moved {
  from = aws_security_group.idp_db[0]
  to   = aws_security_group.idp_db
}

moved {
  from = aws_security_group_rule.idp_db_ingress_ecs[0]
  to   = aws_security_group_rule.idp_db_ingress_ecs
}

moved {
  from = aws_security_group_rule.idp_ecs_egress_db[0]
  to   = aws_security_group_rule.idp_ecs_egress_db
}

moved {
  from = aws_security_group_rule.idp_db_egress_privatelink[0]
  to   = aws_security_group_rule.idp_db_egress_privatelink
}
