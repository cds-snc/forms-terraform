#
# Route53 hosted zone:
# Holds the DNS records for the service
#
resource "aws_route53_zone" "form_viewer" {
  name = var.domain

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
  }
}
