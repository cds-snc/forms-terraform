resource "aws_route53_record" "idp" {
  count   = length(local.idp_domains)
  zone_id = var.hosted_zone_ids[count.index]
  name    = local.idp_domains[count.index]
  type    = "A"

  alias {
    name                   = aws_lb.idp.dns_name
    zone_id                = aws_lb.idp.zone_id
    evaluate_target_health = true
  }
}

#
# Certificate validation
# 
locals {
  # Temporary workaround for the removal of the `forms-formulaires.canada.ca` hosted zone.
  # This will allow the module to plan correctly before the `/aws/hosted_zone` module
  # has been applied.
  domain_name_to_zone_id = {
    (var.domains[0]) = var.hosted_zone_ids[0]
  }
}


# ACM certification validation
resource "aws_route53_record" "idp_validation" {
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
  zone_id         = local.domain_name_to_zone_id[each.value.domain]
}

resource "aws_acm_certificate_validation" "idp" {
  certificate_arn         = aws_acm_certificate.idp.arn
  validation_record_fqdns = [for record in aws_route53_record.idp_validation : record.fqdn]
}

# SES domain validation
resource "aws_route53_record" "idp_ses_verification_TXT" {
  zone_id = local.hosted_zone_id
  name    = "_amazonses.${aws_ses_domain_identity.idp.id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.idp.verification_token]
}

# Email sending
resource "aws_route53_record" "idp_spf_TXT" {
  zone_id = local.hosted_zone_id
  name    = local.ipd_domains[0]
  type    = "TXT"
  ttl     = "300"
  records = [
    "v=spf1 include:amazonses.com -all"
  ]
}

resource "aws_route53_record" "idp_dkim_CNAME" {
  count   = 3
  zone_id = local.hosted_zone_id
  name    = "${element(aws_ses_domain_dkim.idp.dkim_tokens, count.index)}._domainkey.${local.ipd_domains[0]}"
  type    = "CNAME"
  ttl     = "300"
  records = [
    "${element(aws_ses_domain_dkim.idp.dkim_tokens, count.index)}.dkim.amazonses.com",
  ]
}

resource "aws_route53_record" "idp_dmarc_TXT" {
  zone_id = local.hosted_zone_id
  name    = "_dmarc.${local.ipd_domains[0]}"
  type    = "TXT"
  ttl     = "300"
  records = [
    "v=DMARC1; p=reject; sp=reject; pct=100; rua=mailto:CDS.SECURITY-SECURITE.SNC@servicecanada.gc.ca"
  ]
}
