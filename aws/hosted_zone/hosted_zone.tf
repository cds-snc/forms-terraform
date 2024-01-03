#
# Route53 hosted zone:
# Holds the DNS records for the service
#

resource "aws_route53_zone" "form_viewer" {
  # checkov:skip=CKV2_AWS_38: Domain Name System Security Extensions signing not required
  # checkov:skip=CKV2_AWS_39: Domain Name System query logging not required
  count = length(var.domains)
  name  = var.domains[count.index]
}