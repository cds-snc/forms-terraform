moved {
  from = aws_acm_certificate.forms_api[0]
  to   = aws_acm_certificate.forms_api
}

moved {
  from = aws_acm_certificate_validation.forms_api[0]
  to   = aws_acm_certificate_validation.forms_api
}

moved {
  from = aws_lb_target_group.forms_api[0]
  to   = aws_lb_target_group.forms_api
}

moved {
  from = aws_lb_listener_certificate.forms_api_https[0]
  to   = aws_lb_listener_certificate.forms_api_https
}

moved {
  from = aws_alb_listener_rule.forms_api[0]
  to   = aws_alb_listener_rule.forms_api
}

moved {
  from = aws_route53_record.forms_api[0]
  to   = aws_route53_record.forms_api
}
