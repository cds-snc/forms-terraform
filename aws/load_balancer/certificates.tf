#
# Domain certificate
#
resource "aws_acm_certificate" "form_viewer" {
  # First entry in domain list is the primary domain
  domain_name               = var.domain[0]
  validation_method         = "DNS"
  subject_alternative_names = var.domain[1]  # length(var.domain) > 1 ? slice(var.domain, 1, length(var.domain) - 1) : []

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}
