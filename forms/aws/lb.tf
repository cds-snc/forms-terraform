###
# AWS LB - Key Retrieval
###

resource "aws_lb_target_group" "forms" {
  name                 = "forms"
  port                 = 3000
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 30
  vpc_id               = aws_vpc.forms.id

  health_check {
    enabled             = true
    interval            = 10
    path                = "/"
    port                = 3000
    matcher             = "301,200"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name                  = "forms"
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_lb_target_group" "forms_2" {
  name                 = "forms-2"
  port                 = 3000
  protocol             = "HTTP"
  target_type          = "ip"
  deregistration_delay = 30
  vpc_id               = aws_vpc.forms.id

  health_check {
    enabled             = true
    interval            = 10
    port                = 3000
    path                = "/"
    matcher             = "301,200"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name                  = "forms-2"
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_lb" "forms" {
  name               = "forms"
  internal           = false #tfsec:ignore:AWS005
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.forms_load_balancer.id
  ]
  subnets = aws_subnet.forms_public.*.id

  tags = {
    Name                  = "forms"
    (var.billing_tag_key) = var.billing_tag_value
  }
}

resource "aws_lb_listener" "forms_https" {
  depends_on = [
    aws_acm_certificate.forms
  ]

  load_balancer_arn = aws_lb.forms.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2019-08"
  certificate_arn   = aws_acm_certificate.forms.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.forms.arn
  }

  lifecycle {
    ignore_changes = [
      default_action # updated by codedeploy
    ]
  }
}

resource "aws_lb_listener" "forms_http" {
  load_balancer_arn = aws_lb.forms.arn
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
