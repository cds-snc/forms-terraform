resource "aws_route53_record" "idp" {
  zone_id = local.hosted_zone_id
  name    = var.domain_idp
  type    = "A"

  alias {
    name                   = aws_lb.idp.dns_name
    zone_id                = aws_lb.idp.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "idp_validation" {
  zone_id = local.hosted_zone_id

  for_each = {
    for dvo in aws_acm_certificate.idp.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
  ttl             = 60
}

resource "aws_acm_certificate_validation" "idp" {
  certificate_arn         = aws_acm_certificate.idp.arn
  validation_record_fqdns = [for record in aws_route53_record.idp_validation : record.fqdn]
}
