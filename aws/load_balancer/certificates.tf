#
# Domain certificate
#

locals {
  domains = concat(var.domains, [aws_lb.form_viewer.dns_name])
}

resource "aws_acm_certificate" "form_viewer" {
  # First entry in domain list is the primary domain
  domain_name               = local.domains[0]
  validation_method         = "DNS"
  subject_alternative_names = length(local.domains) > 1 ? setsubtract(local.domains, [local.domains[0]]) : []

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
  domain_name               = local.domains[0]
  validation_method         = "DNS"
  subject_alternative_names = length(local.domains) > 1 ? setsubtract(local.domains, [local.domains[0]]) : []

  provider = aws.us-east-1

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}
