output "gc_forms_application_health_check_id" {
  description = "GC Forms application health check identifier"
  value       = aws_route53_health_check.gc_forms_application.id
}

output "maintenance_mode_cloudfront_distribution_domain_name" {
  description = "Domain name of Cloudfront distribution for maintenance mode"
  value       = aws_cloudfront_distribution.maintenance_mode.domain_name
}

output "maintenance_mode_cloudfront_distribution_hosted_zone_id" {
  description = "Hosted zone identifier of Cloudfront distribution for maintenance mode"
  value       = aws_cloudfront_distribution.maintenance_mode.hosted_zone_id
}