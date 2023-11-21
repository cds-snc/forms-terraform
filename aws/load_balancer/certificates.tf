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

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
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

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_acm_certificate_validation" "form_viewer_maintenance_mode_cloudfront_certificate" {
  certificate_arn         = aws_acm_certificate.form_viewer_maintenance_mode.arn
  validation_record_fqdns = [for record in aws_route53_record.form_viewer_maintenance_mode_certificate_validation : record.fqdn]

  provider = aws.us-east-1
}