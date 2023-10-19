resource "aws_shield_protection" "alb" {
  name         = "LoadBalancer"
  resource_arn = aws_lb.form_viewer.arn

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}

resource "aws_shield_protection" "route53_hosted_zone" {
  count        = length(var.hosted_zone_id)
  name         = "Route53HostedZone"
  resource_arn = "arn:aws:route53:::hostedzone/${var.hosted_zone_id[count.index]}"

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
  }
}
