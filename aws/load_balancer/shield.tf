resource "aws_shield_protection" "alb" {
  name         = "LoadBalancer"
  resource_arn = aws_lb.form_viewer.arn


}

resource "aws_shield_protection" "route53_hosted_zone" {
  count        = length(var.hosted_zone_ids)
  name         = "Route53HostedZone"
  resource_arn = "arn:aws:route53:::hostedzone/${var.hosted_zone_ids[count.index]}"


}
