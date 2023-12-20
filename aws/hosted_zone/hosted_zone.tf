#
# Route53 hosted zone:
# Holds the DNS records for the service
#
resource "aws_route53_zone" "form_viewer" {
  count = length(var.domains)
  name  = var.domains[count.index]
}
