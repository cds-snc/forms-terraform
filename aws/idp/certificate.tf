resource "aws_acm_certificate" "idp" {
  domain_name               = local.idp_domains[0]
  validation_method         = "DNS"
  subject_alternative_names = length(local.idp_domains) > 1 ? setsubtract(local.idp_domains, [local.idp_domains[0]]) : []

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}