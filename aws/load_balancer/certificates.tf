#
# Domain certificate
#
resource "aws_acm_certificate" "form_viewer" {
  count             = length(var.domain)
  domain_name       = var.domain[count.index]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}
