#
# Route53 hosted zone:
# Holds the DNS records for the service
#
resource "aws_route53_zone" "form_viewer" {
  count = length(var.domains)
  name  = var.domains[count.index]

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    "Terraform"           = true
  }
}
