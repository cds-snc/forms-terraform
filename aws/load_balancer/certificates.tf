#
# Domain certificate
#
resource "aws_acm_certificate" "form_viewer" {
  # First entry in domain list is the primary domain
  domain_name               = var.domains[0]
  validation_method         = "DNS"
  # subject_alternative_names = length(var.domains) > 1 ? setsubtract(var.domains, [var.domains[0]]) : []

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}
