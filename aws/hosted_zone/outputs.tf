output "hosted_zone_ids" {
  description = "Route53 hosted zone ID"
  value       = slice(aws_route53_zone.form_viewer.*.zone_id, length(aws_route53_zone.form_viewer.*.zone_id) > 1 ? 1 : 0, length(aws_route53_zone.form_viewer.*.zone_id))
}

output "hosted_zone_names" {
  description = "Route53 hosted zone name"
  value       = slice(aws_route53_zone.form_viewer.*.name, length(aws_route53_zone.form_viewer.*.zone_id) > 1 ? 1 : 0, length(aws_route53_zone.form_viewer.*.zone_id))
}
