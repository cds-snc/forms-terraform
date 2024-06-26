resource "aws_acm_certificate" "idp" {
  domain_name       = var.domain_idp
  validation_method = "DNS"

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}
