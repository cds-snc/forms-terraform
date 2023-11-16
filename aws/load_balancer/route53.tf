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

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier  = "form_viewer_${var.domains[count.index]}_primary"
  health_check_id = aws_route53_health_check.gc_forms_application.id
}

resource "aws_route53_record" "form_viewer_maintenance" {
  # checkov:skip=CKV2_AWS_23: False-positive, record is attached to Cloudfront domain name
  count   = length(var.domains)
  zone_id = var.hosted_zone_ids[count.index]
  name    = var.domains[count.index]
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.maintenance_mode.domain_name
    zone_id                = aws_cloudfront_distribution.maintenance_mode.hosted_zone_id
    evaluate_target_health = false
  }

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "form_viewer_${var.domains[count.index]}_secondary"
}

#
# Certificate validation
# 
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
  zone_id         = local.domain_name_to_zone_id[each.value.domain]

}

resource "aws_route53_health_check" "gc_forms_application" {
  fqdn              = aws_lb.form_viewer.dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/form-builder/edit"
  failure_threshold = "2"
  request_interval  = "30"

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}