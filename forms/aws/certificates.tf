resource "aws_acm_certificate" "form_viewer" {
  domain_name       = var.route53_zone_name
  validation_method = "DNS"

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }

  lifecycle {
    create_before_destroy = true
  }
}
