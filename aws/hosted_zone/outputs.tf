output "hosted_zone_ids" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.form_viewer.*.zone_id
}

output "hosted_zone_names" {
  description = "Route53 hosted zone name"
  value       = aws_route53_zone.form_viewer.*.name
}
