resource "aws_shield_subscription" "forms" {
  auto_renew = "ENABLED"
}

resource "aws_shield_protection" "alb" {
  name         = "LoadBalancer"
  resource_arn = aws_lb.form_viewer.arn

  tags = var.core_tags
}

resource "aws_shield_protection_health_check_association" "forms" {
  shield_protection_id = aws_shield_protection.alb.id
  health_check_arn     = aws_route53_health_check.lb_web_app_global_target_group.arn
}

resource "aws_shield_application_layer_automatic_response" "forms" {
  resource_arn = aws_lb.form_viewer.arn

  // AWS best practices: "Enable automatic mitigation in Count mode until Shield Advanced has established a baseline for normal, historic traffic. Shield Advanced needs from 24 hours to 30 days to establish a baseline."
  // We can switch to `BLOCK` once this code has been in Production for a month.
  action = "COUNT"
}

resource "aws_shield_protection" "route53_hosted_zone" {
  count        = length(var.hosted_zone_ids)
  name         = "Route53HostedZone"
  resource_arn = "arn:aws:route53:::hostedzone/${var.hosted_zone_ids[count.index]}"

  tags = var.core_tags
}
