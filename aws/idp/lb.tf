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
    port              = 8080
    protocol          = "HTTP"
    protocol_versions = join(",", local.protocol_versions)
  }
}

resource "aws_lb_target_group" "idp" {
  for_each = local.protocol_versions

  name                 = "idp-tg-${each.value}-${random_string.idp_alb_tg_suffix.result}"
  port                 = 8080
  protocol             = "HTTP"
  protocol_version     = each.value
  target_type          = "ip"
  deregistration_delay = 30
  vpc_id               = var.vpc_id

  health_check {
    enabled  = true
    protocol = "HTTP"
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
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-FIPS-2023-04"
  certificate_arn   = aws_acm_certificate.idp.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.idp["HTTP2"].arn
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

# Send REST API endpoint requests to the HTTP1 target group
# All other requests are sent to the HTTP2 target group
resource "aws_alb_listener_rule" "idp_protocol_version" {
  listener_arn = aws_lb_listener.idp.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.idp["HTTP1"].arn
  }

  condition {
    path_pattern {
      values = ["/*/v?/*", "/.well-known/openid-configuration", "/debug/ready"] # REST API endpoints
    }
  }
}

resource "aws_shield_protection" "idp" {
  name         = "LoadBalancerIdP"
  resource_arn = aws_lb.idp.arn
}
