#
# Route53 records
#
resource "aws_route53_record" "form_viewer" {
  count   = length(var.domain)
  zone_id = var.hosted_zone_id[count.index]
  name    = var.domain[count.index]
  type    = "A"

  alias {
    name                   = aws_lb.form_viewer.dns_name
    zone_id                = aws_lb.form_viewer.zone_id
    evaluate_target_health = true
  }
}

#
# Certificate validation
# 
locals {
  cert_validation_by_zone_id = setproduct(var.hosted_zone_id, [for dvo in aws_acm_certificate.form_viewer.domain_validation_options : {
    name   = dvo.resource_record_name
    type   = dvo.resource_record_type
    record = dvo.resource_record_value
  }])
}


resource "aws_route53_record" "form_viewer_certificate_validation" {

for_each = {
  for idx, entry in local.cert_validation_by_zone_id : idx => {
    zone_id = entry[0]
    name   = entry[1].name
    type   = entry[1].type
    record = entry[1].record
  }
}
  allow_overwrite = true
  zone_id = each.value.zone_id
  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type

  ttl = 60
}
