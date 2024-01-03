#
# Route53 hosted zone:
# Holds the DNS records for the service
#

resource "aws_route53_zone" "form_viewer" {
  # checkov:skip=CKV2_AWS_38: Domain Name System Security Extensions not required
  count = length(var.domains)
  name  = var.domains[count.index]
}