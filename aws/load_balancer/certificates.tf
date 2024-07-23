#
# Domain certificate
#

resource "aws_acm_certificate" "form_viewer" {
  domain_name               = local.app_primary_domain
  validation_method         = "DNS"
  subject_alternative_names = local.cert_subject_alternative_names

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "form_viewer_maintenance_mode" {
  domain_name               = local.app_primary_domain
  validation_method         = "DNS"
  subject_alternative_names = local.cert_subject_alternative_names

  provider = aws.us-east-1

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "form_viewer_maintenance_mode_cloudfront_certificate" {
  certificate_arn         = aws_acm_certificate.form_viewer_maintenance_mode.arn
  validation_record_fqdns = [for record in aws_route53_record.form_viewer_maintenance_mode_certificate_validation : record.fqdn]

  provider = aws.us-east-1
}
