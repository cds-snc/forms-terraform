#
# Domain certificate
#

resource "aws_acm_certificate" "form_viewer" {
  # First entry in domain list is the primary domain
  domain_name               = var.domains[0]
  validation_method         = "DNS"
  subject_alternative_names = length(var.domains) > 1 ? setsubtract(var.domains, [var.domains[0]]) : []

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "form_viewer_maintenance_mode" {
  # First entry in domain list is the primary domain
  domain_name               = var.domains[0]
  validation_method         = "DNS"
  subject_alternative_names = length(var.domains) > 1 ? setsubtract(var.domains, [var.domains[0]]) : []

  provider = aws.us-east-1

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "forms_api" {
  count = var.feature_flag_api ? 1 : 0

  domain_name       = var.domain_api
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

moved {
  from = aws_acm_certificate.form_api
  to   = aws_acm_certificate.forms_api
}

resource "aws_acm_certificate_validation" "form_viewer_maintenance_mode_cloudfront_certificate" {
  certificate_arn         = aws_acm_certificate.form_viewer_maintenance_mode.arn
  validation_record_fqdns = [for record in aws_route53_record.form_viewer_maintenance_mode_certificate_validation : record.fqdn]

  provider = aws.us-east-1
}

resource "aws_acm_certificate_validation" "forms_api" {
  count = var.feature_flag_api ? 1 : 0

  certificate_arn         = aws_acm_certificate.forms_api[0].arn
  validation_record_fqdns = [for record in aws_route53_record.forms_api_certificate_validation : record.fqdn]
}

moved {
  from = aws_acm_certificate_validation.form_api
  to   = aws_acm_certificate_validation.forms_api
}
