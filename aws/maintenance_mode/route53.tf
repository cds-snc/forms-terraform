resource "aws_route53_health_check" "gc_forms_application" {
  fqdn              = var.domains[0]
  port              = "443"
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = "2"
  request_interval  = "30"

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}