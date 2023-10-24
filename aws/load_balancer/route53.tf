#
# Route53 records
#
resource "aws_route53_record" "form_viewer" {
  count   = length(var.domains)
  zone_id = var.hosted_zone_ids[count.index]
  name    = var.domains[count.index]
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
# locals {
#   cert_validation_by_zone_id = setproduct(var.hosted_zone_ids, [for dvo in aws_acm_certificate.form_viewer.domain_validation_options : {
#     name   = dvo.resource_record_name
#     type   = dvo.resource_record_type
#     record = dvo.resource_record_value
#   }])
# }

locals {
  domain_name_to_zone_id = zipmap(var.domains, var.hosted_zone_ids)
}


resource "aws_route53_record" "form_viewer_certificate_validation" {
  for_each = {
    for dvo in aws_acm_certificate.form_viewer.domain_validation_options : dvo.domain_name => {
      domain = dvo.domain_name
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = domain_name_to_zone_id[each.value.domain]

}
