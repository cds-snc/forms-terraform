#
# Load balancer
#

resource "aws_lb" "form_viewer" {
  name               = "form-viewer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  drop_invalid_header_fields = true
  enable_deletion_protection = true

  access_logs {
    bucket  = var.cbs_satellite_bucket_name
    prefix  = "lb_logs"
    enabled = true
  }

  tags = {
    Name = "form_viewer"
  }
}

resource "aws_lb_target_group" "form_viewer_1" {
  name                 = "form-viewer"
  port                 = 3000
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 30
  vpc_id               = var.vpc_id

  health_check {
    enabled             = true
    interval            = 10
    path                = "/en/form-builder"
    port                = 3000
    matcher             = "200"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "form_viewer_1"
  }
}

resource "aws_lb_target_group" "form_viewer_2" {
  name                 = "form-viewer-2"
  port                 = 3000
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 30
  vpc_id               = var.vpc_id

  health_check {
    enabled             = true
    interval            = 10
    port                = 3000
    path                = "/en/form-builder"
    matcher             = "200"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "form_viewer_2"
  }
}

resource "aws_lb_target_group" "forms_api" {
  name                 = "forms-api"
  port                 = 3001
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 30
  vpc_id               = var.vpc_id

  health_check {
    enabled             = true
    interval            = 10
    port                = 3001
    path                = "/status"
    matcher             = "200"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "forms_api"
  }
}

resource "aws_lb_listener" "form_viewer_https" {
  depends_on = [
    aws_acm_certificate.form_viewer
  ]

  load_balancer_arn = aws_lb.form_viewer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-FIPS-2023-04"
  certificate_arn   = aws_acm_certificate.form_viewer.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.form_viewer_1.arn
  }

  lifecycle {
    ignore_changes = [
      default_action # updated by codedeploy
    ]
  }
}

resource "aws_lb_listener_certificate" "forms_api_https" {
  listener_arn    = aws_lb_listener.form_viewer_https.arn
  certificate_arn = aws_acm_certificate_validation.forms_api.certificate_arn
}

resource "aws_lb_listener" "form_viewer_http" {
  load_balancer_arn = aws_lb.form_viewer.arn
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

  lifecycle {
    ignore_changes = [
      default_action # updated by codedeploy
    ]
  }
}

resource "aws_alb_listener_rule" "forms_api" {
  listener_arn = aws_lb_listener.form_viewer_https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.forms_api.arn
  }

  condition {
    host_header {
      values = [var.domain_api]
    }
  }
}
