#
# Route53 hosted zone:
# Holds the DNS records for the service
#

resource "aws_route53_zone" "form_viewer" {
  # checkov:skip=CKV2_AWS_38: Domain Name System Security Extensions signing not required
  # checkov:skip=CKV2_AWS_39: Domain Name System query logging not required
  // TODO: Implement Domain Name System Security Extensions signing
  // TODO: Implement Domain Name System query logging
  for_each = toset(var.domains)
  name     = each.key
}


moved {
  from = aws_route53_zone.form_viewer[0]
  to   = aws_route53_zone.form_viewer[var.domains[1]]
}