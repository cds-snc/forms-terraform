resource "aws_lb" "idp" {
  name               = "idp"
  internal           = false
  load_balancer_type = "application"

  drop_invalid_header_fields = true
  enable_deletion_protection = true

  security_groups = [var.security_group_idp_lb_id]
  subnets         = var.public_subnet_ids

  access_logs {
    bucket  = var.cbs_satellite_bucket_name
    prefix  = "lb_logs"
    enabled = true
  }

  tags = local.common_tags
}

resource "random_string" "idp_alb_tg_suffix" {
  length  = 3
  special = false
  upper   = false
  keepers = {
    port             = 8080
    protocol         = "HTTPS"
    protocol_version = "HTTP2"
  }
}

resource "aws_lb_target_group" "idp" {
  name                 = "idp-tg-${random_string.idp_alb_tg_suffix.result}"
  port                 = 8080
  protocol             = "HTTPS"
  protocol_version     = "HTTP2"
  target_type          = "ip"
  deregistration_delay = 30
  vpc_id               = var.vpc_id

  health_check {
    enabled  = true
    protocol = "HTTPS"
    path     = "/debug/healthz"
    matcher  = "200-399"
  }

  stickiness {
    type = "lb_cookie"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      stickiness[0].cookie_name
    ]
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "idp" {
  load_balancer_arn = aws_lb.idp.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.idp.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.idp.arn
  }

  depends_on = [
    aws_acm_certificate_validation.idp,
    aws_route53_record.idp_validation,
  ]

  tags = local.common_tags
}

resource "aws_lb_listener" "idp_http_redirect" {
  load_balancer_arn = aws_lb.idp.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = local.common_tags
}

resource "aws_shield_protection" "alb" {
  name         = "LoadBalancer"
  resource_arn = aws_lb.idp.arn
}
