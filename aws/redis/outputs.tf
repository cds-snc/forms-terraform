output "redis_url" {
  description = "The Redis endpoint URL"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}
