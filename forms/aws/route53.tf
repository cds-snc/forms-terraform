###
# Route53 Zone
###

resource "aws_route53_zone" "form_viewer" {
  name = var.route53_zone_name

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}

###
# Route53 Record - Forms
###

resource "aws_route53_record" "form_viewer" {
  zone_id = aws_route53_zone.form_viewer.zone_id
  name    = aws_route53_zone.form_viewer.name
  type    = "A"

  alias {
    name                   = aws_lb.form_viewer.dns_name
    zone_id                = aws_lb.form_viewer.zone_id
    evaluate_target_health = true
  }
}

# Certificate validation

resource "aws_route53_record" "form_viewer_certificate_validation" {
  zone_id = aws_route53_zone.form_viewer.zone_id

  for_each = {
    for dvo in aws_acm_certificate.form_viewer.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type

  ttl = 60
}